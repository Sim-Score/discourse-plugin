require "net/http"
require "uri"
require "json"

module Simscore
  class ApiService
    def self.analyze_posts(posts)
      Rails.logger.info(
        "SimScore: Analysis started in API service with posts: #{
          { post_count: posts.size }.to_json
        }",
      )
      uri = URI.parse("#{SiteSetting.simscore_api_endpoint}/v1/rank_ideas")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      # Split posts into paragraphs and format for API
      ideas = []
      posts.each_with_index do |post, post_index|
        # Split post into paragraphs (split by double newline)
        Rails.logger.info(
          "SimScore: Processing post: #{
            {
              post_id: post.id,
              post_number: post.post_number,
              author: post.user&.username,
              post_index: post_index,
            }.to_json
          }",
        )
        paragraphs = post.raw.split(/\n\s*\n/).reject(&:blank?)

        paragraphs.each_with_index do |paragraph, para_index|
          ideas << {
            id: "#{post_index}-#{para_index}",
            idea: paragraph.strip,
            author_id: post.user&.username || "unknown",
          }
        end
      end

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{SiteSetting.simscore_api_key}"

      request_body = { ideas: ideas }
      request.body = request_body.to_json

      Rails.logger.info(
        "SimScore: Sending API request - #{
          { endpoint: uri.to_s, idea_count: ideas.size, request_body: request_body }.to_json
        }",
      )

      response = http.request(request)

      Rails.logger.info(
        "SimScore: Received API response - #{
          { status: response.code, body: response.body }.to_json
        }",
      )

      unless response.is_a?(Net::HTTPSuccess)
        raise "SimScore API error: #{response.code} - #{response.body}"
      end

      JSON.parse(response.body)
    end

    def self.format_results(results)
      Rails.logger.info("SimScore: Formatting results - #{{ results: results }.to_json}")

      output = ["# SimScore Analysis Results\n\n"]

      # Add ranked ideas if available
      if results["ranked_ideas"].present?
        output << "## Top 10 Most Similar Paragraphs\n\n"
        results["ranked_ideas"]
          .first(10)
          .each do |idea|
            post_num, para_num = idea["id"].split("-").map(&:to_i)
            score = (idea["similarity_score"] * 100).round(1)
            author = idea["author_id"]

            output << "### Post ##{post_num + 1}, Paragraph #{para_num + 1} (#{score}% similarity)\n"
            output << "_Author: @#{author}_\n\n"
            output << "#{idea["idea"]}\n\n"
          end
      else
        output << "No ranked ideas found in the results.\n\n"
      end

      # Add cluster information if available
      if results["cluster_names"].present? && !results["cluster_names"].nil?
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
