# frozen_string_literal: true

# name: simscore
# about: Analyzes similarity scores for posts in a topic
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :simscore_enabled

after_initialize do
  module ::Simscore
    PLUGIN_NAME = "simscore"
  end
  require_relative "lib/simscore/engine"

  Discourse::Application.routes.append { mount ::Simscore::Engine, at: "/simscore" }

  # Add permission method to Guardian
  add_to_class(:guardian, :can_use_simscore?) { SiteSetting.simscore_enabled }

  add_to_serializer(:current_user, :can_use_simscore) { SiteSetting.simscore_enabled }
end
