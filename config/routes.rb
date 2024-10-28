# frozen_string_literal: true

Rails.application.routes.draw do
  resources :tokens, only: :create
  delete '/tokens', to: 'tokens#destroy'
  get '/validate', to: 'tokens#validate'
  post '/renew', to: 'tokens#renew'
end
