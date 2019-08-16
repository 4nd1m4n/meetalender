Meetalender::Engine.routes.draw do
  root to: "meetups#index"
  resources :meetups, except: [:show] do
    collection do
      get  'authorize_calendar'
      post 'authorize_calendar'
      get 'authorize_meetup'
      get 'callback'
      get 'failure'
    end
  end
end
