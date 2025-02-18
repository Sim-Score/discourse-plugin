import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { getOwner } from "@ember/application";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class SimscoreButton extends Component {
  @service currentUser;
  @tracked loading = false;

  get logger() {
    return getOwner(this).lookup("service:logger");
  }

  @action
  async calculateSimScore() {
    try {
      this.logger.debug(
        "SimScore: Starting calculation for topic",
        this.args.topic.id
      );
      this.loading = true;
      const response = await ajax(`/simscore/analyze/${this.args.topic.id}`, {
        type: "POST",
      });

      this.logger.debug("SimScore: Received response", response);

      if (response.success) {
        this.logger.debug(
          "SimScore: Calculation successful, post created with ID:",
          response.post_id
        );
        this.args.showSuccess?.(i18n("simscore.success"));
      } else {
        this.logger.error("SimScore: API returned error:", response.errors);
        this.args.showError?.(i18n("simscore.error"));
      }
    } catch (error) {
      this.logger.error("SimScore: Failed to calculate:", error);
      popupAjaxError(error);
      this.args.showError?.(i18n("simscore.error"));
    } finally {
      this.loading = false;
    }
  }

  <template>
    <DButton
      class="btn-primary simscore-button"
      @action={{this.calculateSimScore}}
      @disabled={{this.loading}}
      @label="simscore.calculate"
    />
  </template>
}
