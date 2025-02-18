require "net/http"
require "uri"
require "json"

module Simscore
  class ApiService
    def self.analyze_posts(posts)
      uri = URI.parse("#{SiteSetting.simscore_api_endpoint}/v1/rank_ideas")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      # Split posts into paragraphs and format for API
      ideas = []
      posts.each_with_index do |post, post_index|
        # Split post into paragraphs (split by double newline)
        paragraphs = post.split(/\n\s*\n/).reject(&:blank?)

        paragraphs.each_with_index do |paragraph, para_index|
          ideas << {
            id: "#{post_index}-#{para_index}",
            idea: paragraph.strip,
            metadata: {
              post_number: post_index + 1,
              paragraph_number: para_index + 1,
              author: post.user&.username || "unknown",
            },
          }
        end
      end

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{SiteSetting.simscore_api_key}"

      request.body = { ideas: ideas, advanced_features: { cluster_names: true } }.to_json

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "SimScore API error: #{response.code} - #{response.body}"
      end

      JSON.parse(response.body)
    end

    def self.format_results(results)
      output = ["# SimScore Analysis Results\n\n"]

      # Add top 10 ranked ideas
      output << "## Top 10 Most Similar Paragraphs\n\n"
      results["ranked_ideas"]
        .first(10)
        .each do |idea|
          post_num, para_num = idea["id"].split("-").map(&:to_i)
          score = (idea["similarity_score"] * 100).round(1)
          author = idea["metadata"]["author"]

          output << "### Post ##{post_num + 1}, Paragraph #{para_num + 1} (#{score}% similarity)\n"
          output << "_Author: @#{author}_\n\n"
          output << "#{idea["idea"]}\n\n"
        end

      # Add cluster information if available
      if results["cluster_names"].present?
        output << "## Topic Clusters\n\n"
        results["cluster_names"].each do |cluster_id, name|
          # Get only top paragraphs from each cluster
          posts_in_cluster =
            results["ranked_ideas"]
              .select { |idea| idea["cluster_id"].to_s == cluster_id.to_s }
              .first(3) # Show only top 3 paragraphs per cluster
              .map do |idea|
                post_num, para_num = idea["id"].split("-").map(&:to_i)
                "Post ##{post_num + 1} (¶#{para_num + 1})"
              end
              .join(", ")

          output << "- **#{name}**: #{posts_in_cluster}\n"
        end
      end

      output.join("")
    end
  end
end
