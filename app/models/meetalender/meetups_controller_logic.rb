require 'multi_json'

module Meetalender
  module MeetupsControllerLogic

    def self.index(view_switch)
      case view_switch
        when "search_mask"
          'search_mask'
        when "search_result"
          search_result()
          'search_result'
        else
          'index'
      end
    end

    def self.authorize_calendar(key_code)
      if !key_code.nil?
        MeetupsCalendarSyncer.authorize_and_remember(key_code)
        redirect_to(action: :index) and return
      end
    end

    def self.authorize_meetup(request)
      credentials_path = AuthCredential.expand_env(ENV['GOOGLE_CALENDAR_JSON'].to_s)
      meetup_credentials = File.open credentials_path.to_s do |f|
        json = f.read
        all_credentials = MultiJson.load json
        all_credentials["meetup"]
      end

      redirect_url = "https://secure.meetup.com/oauth2/authorize" +
        "?client_id=#{meetup_credentials["client_id"]}" +
        "&response_type=code" +
        "&redirect_uri=#{request.protocol}#{request.host_with_port}#{callback_meetups_path.to_s}"
    end

    def self.callback(code)
      return_message = {type: :success, message: "Successfully authorized Meetup API"}
      credentials_path = AuthCredential.expand_env(ENV['GOOGLE_CALENDAR_JSON'].to_s)
      meetup_credentials = File.open credentials_path.to_s do |f|
        json = f.read
        all_credentials = MultiJson.load json
        all_credentials["meetup"]
      end

      request_uri = "https://secure.meetup.com/oauth2/access"
      request_query_hash = {"client_id": meetup_credentials["client_id"], "client_secret": meetup_credentials["client_secret"], "grant_type": "authorization_code", "redirect_uri": "http://127.0.0.1:3000/admin/meetups/callback", "code": "#{code}"}

      client = HTTPClient.new
      begin
        response = JSON.parse(client.post_content(request_uri, request_query_hash))
        puts response
      rescue => ex
        return_message = {type: :danger, message: "Error: " + ex.message.to_s}
      end

      if !response.nil?
        token_store = Google::Auth::Stores::DbTokenStore.new
        token_store.store("meetup", {"auth_id": "meetup", "client_id": meetup_credentials["client_id"], "access_token": response["access_token"], "refresh_token": response["refresh_token"], "scope": "", "expiration_time_millis": response["expires_in"] * 1000}.to_json.to_s)
      end

      return_message
    end

    def search_result
      group_params = JSON.parse(params_permit_parameters[:parameters])

      groups = MeetupsCalendarSyncer.get_path_authorized("/find/groups", group_params.merge({"fields" => "last_event"}))

      @groups_id_name = groups.map{|g| {id: g["id"].to_i, name: g["name"].to_s, link: g["link"].to_s} }
      group_ids = groups.map{|g| g["id"]}
      upcoming_events = MeetupsCalendarSyncer.get_path_authorized("/find/upcoming_events", {"page": 200})
      upcoming_events = upcoming_events.nil? ? [] : upcoming_events["events"]

      upcoming_events_of_groups = upcoming_events.select{|e| !e["group"].nil? && group_ids.include?(e["group"]["id"])}

      grouped_upcoming_events = upcoming_events_of_groups.group_by{|e| e["group"]["id"]}
      limited_upcoming_events = Hash[grouped_upcoming_events.map{|k, v| [k, v.select{|e| Time.at(Rational(e["time"], 1000)) > Time.now}.sort_by{|e| e["time"]}.take(2)]}].select{|k, v| v.any?}

      @found_upcoming_grouped_events = limited_upcoming_events

      last_events = Hash[groups.group_by{|g| g["id"]}.map{|k, v| [k, v.map{|g| g["last_event"]}]}].select{|k, v| v.any?}
      @found_last_grouped_events = last_events

      @meetup_groups = groups.map{|g| Meetup.new({"group_id": g["id"], "name": g["name"], "approved_cities": ""})}
    end

  end
end