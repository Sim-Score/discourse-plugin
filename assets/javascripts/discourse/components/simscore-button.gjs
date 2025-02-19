import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class SimscoreButton extends Component {
  @service currentUser;
  @service siteSettings;
  @service dialog;
  @tracked loading = false;
  @tracked ideas = [];

  @action
  async calculateSimScore() {
    // eslint-disable-next-line no-console
    console.info("Debug: args received:", {
      args: this.args,
      outletArgs: this.args?.outletArgs,
      topic: this.args?.topic,
    });

    // eslint-disable-next-line no-console
    console.info("Debug: raw args:", this.args);

    try {
      if (!this.args?.topic?.id) {
        // eslint-disable-next-line no-console
        console.error("❌ SimScore: No topic ID found");
        this.dialog.alert({
          message: "Error: Cannot find topic ID",
        });
        return;
      }

      const topicId = this.args.topic.id;
      const username = this.currentUser?.username;

      // eslint-disable-next-line no-console
      console.info("SimScore: Button pressed", {
        topicId,
        username,
        timestamp: new Date().toISOString(),
        topicTitle: this.args.topic?.title,
        postCount: this.args.topic?.posts_count,
      });

      // Show a notification to the user
      this.dialog.alert({
        message: `Starting SimScore analysis for topic ${this.args.topic.title}...`,
      });

      this.loading = true;
      // eslint-disable-next-line no-console
      console.info("🔵 SimScore: Analysis started...");

      // Ensure we have at least 4 ideas as per API requirements
      // if (this.ideas.length < 4) {
      //   this.dialog.alert({
      //     message: "At least 4 ideas are required for analysis",
      //   });
      //   this.loading = false;
      //   return;
      // }

      const formattedIdeas = [
        ...this.ideas.map((idea, index) => ({
          id: String(index + 1),
          idea,
        })),
        {
          id: this.ideas.length + 1,
          idea: "Improve user engagement through gamification",
        },
        {
          id: this.ideas.length + 2,
          idea: "Implement a reward system for active contributors",
        },
        {
          id: this.ideas.length + 3,
          idea: "Add social sharing features",
        },
        {
          id: this.ideas.length + 4,
          idea: "Create a mobile-friendly interface",
        },
      ];

      const payload = {
        ideas: formattedIdeas,
        advanced_features: {
          relationship_graph: false,
          cluster_names: false,
          pairwise_similarity_matrix: false,
        },
      };

      try {
        // eslint-disable-next-line no-console
        console.info("🔵 Debug payload:", payload);
        const apiUrl = "https://simscore-api-dev.fly.dev/v1/rank_ideas";
        // eslint-disable-next-line no-console
        console.info("🔵 Making API request to:", apiUrl);

        const response = await ajax(apiUrl, {
          type: "POST",
          contentType: "application/json",
          dataType: "json",
          crossDomain: true,
          xhrFields: {
            withCredentials: true,
          },
          headers: {
            Accept: "application/json",
            "Access-Control-Allow-Origin": "*",
            Authorization:
              "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNWNhZWU2MTQtNTEzZS00NTljLTllN2UtNDM0MzYyMGFlMjlhIiwiZW1haWwiOiJtaWtoYWlsb3YuYW50QGdtYWlsLmNvbSIsImlzX2d1ZXN0IjpmYWxzZSwia2V5X2lkIjoiNWQ2YTVhYjEtNjI2Zi00MTFmLWE2ZWYtYTg3NjBjNTVlYTI5IiwidG9rZW5fdHlwZSI6ImFwaV9rZXkifQ.k3_qSLw1NbtT65S1yC1FQbVfMm8sRgL8x4FQnDkB8n0",
          },
          data: JSON.stringify(payload),
        });

        // eslint-disable-next-line no-console
        console.info("🟢 API Response:", response);

        if (response.ranked_ideas) {
          const score = response.ranked_ideas[0].similarity_score;
          // eslint-disable-next-line no-console
          console.info("✅ SimScore: Analysis complete!", score);
          this.dialog.alert({
            message: `SimScore analysis completed! Score: ${(
              score * 100
            ).toFixed(1)}%`,
          });
        } else {
          throw new Error("Invalid response format");
        }
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error("❌ API Error:", error);
        // eslint-disable-next-line no-console
        console.error("❌ Error details:", {
          message: error.message,
          status: error.status,
          stack: error.stack,
        });
        throw error;
      } finally {
        // eslint-disable-next-line no-console
        console.info("🔵 SimScore: Operation completed");
        this.loading = false;
      }
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error("❌ SimScore: Exception:", error.message, error.stack);
      this.dialog.alert({
        message: `Error: ${error.message}`,
      });
      popupAjaxError(error);
    }
  }

  <template>
    <DButton
      class="btn-primary simscore-button"
      @action={{this.calculateSimScore}}
      @disabled={{this.loading}}
      @icon="calculator"
      @translatedLabel="Calculate SimScore"
    />
  </template>
}
