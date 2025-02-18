# frozen_string_literal: true

Simscore::Engine.routes.draw do
  get "/examples" => "examples#index"
  post "/analyze/:topic_id" => "analyze#create"
  # define routes here
end
