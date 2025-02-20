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

      this.loading = true;
      // eslint-disable-next-line no-console
      console.info("🔵 SimScore: Analysis started...");

      try {
        const response = await ajax(`/simscore/analyze/${topicId}`, {
          type: "POST",
          data: {},
        });

        // eslint-disable-next-line no-console
        console.info("🟢 API Response:", response);

        if (response.success) {
          // eslint-disable-next-line no-console
          console.info("✅ SimScore: Analysis complete!");
          this.dialog.alert({
            message: `SimScore analysis completed! Check the new post in the topic.`,
          });
        } else {
          throw new Error(response.errors?.join(", ") || "Analysis failed");
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
        message: `❌ SimScore: Error: ${error.message}`,
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
