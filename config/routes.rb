# frozen_string_literal: true

Rails.application.routes.draw do
  resources :tokens, only: [:create] do
    collection do
      delete :destroy
      get :validate
      post :renew
    end
  end
end
