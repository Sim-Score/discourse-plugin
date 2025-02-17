# frozen_string_literal: true

Simscore::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::Simscore::Engine, at: "simscore" }
