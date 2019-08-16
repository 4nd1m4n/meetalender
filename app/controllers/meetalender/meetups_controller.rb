module Meetalender
  class MeetupsController < ApplicationController
    before_action :build_meetup_group, only: [:new, :create]
    before_action :load_meetup_group,  only: [:show, :edit, :update, :destroy]

    def index
      # @meetups = MeetupGroup.page(params[:page])
      # One might want to paginate the MeetupGroup's
      @meetups = MeetupGroup.all
      render Meetalender::MeetupsControllerLogic::index(params_permit_switch[:switch])
    end

    def show_message(message = {})
      # flash.now[message.fetch(:type, ":notice")] = message.fetch(:message, message.to_s).to_s
      # One might want to overwrite this function with an appropriate message shower for the used environment
      # This one will "only" write the message to the console (where the user might not see it).
      puts message.fetch(:type, ":notice").to_s + message.fetch(:message, message.to_s).to_s
    end

    def authorize_calendar
      @goto_url = MeetupsCalendarSyncer.get_authorization_url
      Meetalender::MeetupsControllerLogic::authorize_calendar(key_code)
    end

    def authorize_meetup
      redirect_to(Meetalender::MeetupsControllerLogic::authorize_meetup(request)) and return
    end

    def callback
      code = params_permit_code[:code]
      show_message(Meetalender::MeetupsControllerLogic::callback(code))
    end

    def failure
      show_message({type: :danger, message: "Meetup authorization failed."})
    end

    def create
      @selected_groups_ids = params_permit_selected[:selected_groups_ids]

      @selected_groups_ids.each do |selected_id|
        group_data = params_permit_id(selected_id)

        @meetup = MeetupGroup.new({"group_id": selected_id, "name": group_data[:name], "approved_cities": group_data[:approved_cities], "group_link": group_data[:group_link]})
        @meetup.save!
        show_message({type: :success, message: "Created new Meetup Subscription(s)."})
      end

      redirect_to(action: :index) and return
    end

    def edit
      # TODO(Schau): Design edit page and functionality.
      # render
    end

    def update
    #   @meetup.update_attributes!(meetup_params)
    #   flash[:success] = 'Meetup updated'
    #   redirect_to action: :show, id: @meetup
    # rescue ActiveRecord::RecordInvalid
    #   flash.now[:danger] = 'Failed to update Meetup'
    #   render action: :edit
    end

    def destroy
      # @meetup.destroy
      # flash[:success] = 'Meetup deleted'
      # redirect_to action: :index
    end

  protected

    def build_meetup_group
      @meetup = MeetupGroup.new(meetup_params)
    end

    def load_meetup_group
      @meetup = MeetupGroup.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      show_message({type: :danger, message: 'Meetup Group not found'})
      redirect_to action: :index
    end

    def meetup_params
      params.fetch(:meetup, {}).permit(:name, :group_id, :approved_cities, :group_link)
    end
    def params_permit_parameters
      params.permit(:parameters)
    end
    def params_permit_selected
      params.permit({selected_groups_ids: []})
    end
    def params_permit_id(selected)
      res = params.require(:groups).permit("#{selected}": [:name, :approved_cities])
      res[selected]
    end
    def params_permit_switch
      params.permit(:switch)
    end
    def params_permit_key_code
      params.permit(:key_code)
    end
    def params_permit_code
      params.permit(:code)
    end
  end

end