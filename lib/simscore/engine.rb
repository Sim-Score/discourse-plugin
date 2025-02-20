# frozen_string_literal: true

module Simscore
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace Simscore

    config.autoload_paths << File.join(config.root, "lib")
  end
end
