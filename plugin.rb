# frozen_string_literal: true

# name: simscore
# about: TODO
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :simscore_enabled

module ::Simscore
  PLUGIN_NAME = "simscore"
end

require_relative "lib/simscore/engine"

after_initialize do
  # Code which should run after Rails has finished booting
end
