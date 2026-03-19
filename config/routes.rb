Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
  patch "workspace_mode", to: "workspace_modes#update", as: :workspace_mode
  resources :forecasts, only: :index do
    post :sync, on: :collection
  end
  get "forecast-stock-orders/new", to: "forecast_stock_orders#new", as: :new_forecast_stock_orders
  post "forecast-stock-orders", to: "forecast_stock_orders#create", as: :forecast_stock_orders
  resources :stock_orders, only: %i[index show]
  post "stock_orders/check_latest", to: "stock_orders#check_latest", as: :check_latest_stock_orders
  resources :sales_interests, only: %i[new create]
  resources :incoming_stocks, only: :index
end
