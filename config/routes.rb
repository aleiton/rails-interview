Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  namespace :api do
    resources :todo_lists, only: %i[index show create update destroy], path: :todolists do
      member do
        post :complete_all
      end
      resources :todo_items, only: %i[index create update destroy], path: :todoitems
    end
  end

  resources :todo_lists, only: %i[index new], path: :todolists
end
