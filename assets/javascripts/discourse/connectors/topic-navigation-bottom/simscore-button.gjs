import Component from "@glimmer/component";
import SimscoreButton from "../../components/simscore-button";

export default class SimscoreButtonConnector extends Component {
  <template>
      <SimscoreButton @topic={{this.args.outletArgs.topic}} />
  </template>
} 