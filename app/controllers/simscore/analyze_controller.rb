module Simscore
  class AnalyzeController < ::ApplicationController
    requires_plugin Simscore::PLUGIN_NAME
    before_action :ensure_logged_in
    before_action :ensure_api_key_configured

    def create
      Rails.logger.info("SimScore: Starting analysis for topic #{params[:topic_id]}")

      topic = Topic.find(params[:topic_id])
      guardian.ensure_can_see!(topic)

      # Get posts with their users
      posts = topic.posts.includes(:user).order(:post_number)
      Rails.logger.info("SimScore: Found #{posts.count} posts to analyze")

      begin
        # Call SimScore API
        Rails.logger.info("SimScore: Calling API service")
        results = ApiService.analyze_posts(posts)
        Rails.logger.info("SimScore: API analysis complete")

        # Format results into markdown
        formatted_results = ApiService.format_results(results)
        Rails.logger.info("SimScore: Results formatted")

        # Try to use SimScore user if available, otherwise use current user
        posting_user = User.find_by(username: "simscore") || current_user
        Rails.logger.info("SimScore: Posting as user #{posting_user.username}")

        # Create a new post with the results
        creator =
          PostCreator.new(
            posting_user,
            topic_id: topic.id,
            raw: formatted_results,
            skip_validations: true,
          )

        post = creator.create

        if post.present?
          Rails.logger.info("SimScore: Successfully created post #{post.id}")
          render json: { success: true, post_id: post.id }
        else
          Rails.logger.error("SimScore: Failed to create post: #{creator.errors.full_messages}")
          render json: { success: false, errors: creator.errors.full_messages }, status: 422
        end
      rescue StandardError => e
        Rails.logger.error(
          "SimScore: Error during analysis: #{e.message}\n#{e.backtrace.join("\n")}",
        )
        render json: { success: false, errors: [e.message] }, status: 422
      end
    end

    private

    def ensure_api_key_configured
      unless SiteSetting.simscore_api_key.present?
        Rails.logger.error("SimScore: API key not configured")
        render json: { success: false, errors: ["SimScore API key not configured"] }, status: 422
      end
    end
  end
end
