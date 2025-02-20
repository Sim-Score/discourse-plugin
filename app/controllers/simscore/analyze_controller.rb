module Simscore
  class AnalyzeController < ::ApplicationController
    requires_plugin Simscore::PLUGIN_NAME
    before_action :ensure_logged_in
    before_action :ensure_api_key_configured

    def create
      Rails.logger.info("SimScore: Analysis started in controller")
      start_time = Time.now
      Rails.logger.info(
        "SimScore: Analysis started with params: #{
          {
            topic_id: params[:topic_id],
            user_id: current_user.id,
            username: current_user.username,
            timestamp: Time.now,
          }.to_json
        }",
      )

      topic = Topic.find(params[:topic_id])
      guardian.ensure_can_see!(topic)

      # Get posts with their users
      posts = topic.posts.includes(:user).order(:post_number)
      Rails.logger.info(
        "SimScore: Posts loaded - #{
          {
            topic_id: topic.id,
            post_count: posts.count,
            topic_title: topic.title,
            duration_ms: ((Time.now - start_time) * 1000).to_i,
          }.to_json
        }",
      )

      begin
        # Call SimScore API
        Rails.logger.info(
          "SimScore: Calling API service - #{
            { topic_id: topic.id, endpoint: SiteSetting.simscore_api_endpoint }.to_json
          }",
        )

        results = ApiService.analyze_posts(posts)

        Rails.logger.info(
          "SimScore: API analysis complete - #{
            {
              topic_id: topic.id,
              duration_ms: ((Time.now - start_time) * 1000).to_i,
              cluster_count: results["cluster_names"]&.size,
            }.to_json
          }",
        )

        # Format results into markdown
        formatted_results = ApiService.format_results(results)
        Rails.logger.info(
          "SimScore: Results formatted - #{
            { topic_id: topic.id, result_length: formatted_results.length }.to_json
          }",
        )

        # Try to use SimScore user if available, otherwise use current user
        posting_user = User.find_by(username: "simscore") || current_user
        Rails.logger.info(
          "SimScore: Selected posting user - #{
            {
              topic_id: topic.id,
              username: posting_user.username,
              user_id: posting_user.id,
            }.to_json
          }",
        )

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
          Rails.logger.info(
            "SimScore: Post created successfully - #{
              {
                topic_id: topic.id,
                post_id: post.id,
                duration_ms: ((Time.now - start_time) * 1000).to_i,
              }.to_json
            }",
          )
          render json: { success: true, post_id: post.id }
        else
          Rails.logger.error(
            "SimScore: Post creation failed - #{
              {
                topic_id: topic.id,
                errors: creator.errors.full_messages,
                duration_ms: ((Time.now - start_time) * 1000).to_i,
              }.to_json
            }",
          )
          render json: { success: false, errors: creator.errors.full_messages }, status: 422
        end
      rescue StandardError => e
        Rails.logger.error(
          "SimScore: Error during analysis - #{
            {
              topic_id: topic.id,
              error: e.message,
              backtrace: e.backtrace[0..5],
              duration_ms: ((Time.now - start_time) * 1000).to_i,
            }.to_json
          }",
        )
        render json: { success: false, errors: [e.message] }, status: 422
      end
    end

    private

    def ensure_api_key_configured
      Rails.logger.info("SimScore: Checking API key present")
      if SiteSetting.simscore_api_key.blank?
        Rails.logger.error(
          "SimScore: API key missing - #{
            { user_id: current_user.id, username: current_user.username }.to_json
          }",
        )
        render json: { success: false, errors: ["SimScore API key not configured"] }, status: 422
      end
    end
  end
end
