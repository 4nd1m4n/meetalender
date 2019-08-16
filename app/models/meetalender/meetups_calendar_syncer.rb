require "date"
require "google/auth/store/db_token_store"
require "google/apis/calendar_v3"
require "googleauth"

require "meetalender/auth_credential"

OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Google Calendar API Ruby MeetupSync".freeze
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_EVENTS

module Meetalender
  module MeetupsCalendarSyncer

    def self.test_function(value1, value2)
      value1 + value2
    end

    def self.prepare_authorizer
      credentials_path = Meetalender::AuthCredential.expand_env(ENV['GOOGLE_CALENDAR_JSON'].to_s)
      client_id = Google::Auth::ClientId.from_file credentials_path
      token_store = Google::Auth::Stores::DbTokenStore.new
      authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
    end

    def self.get_authorization_url
      self.prepare_authorizer.get_authorization_url base_url: OOB_URI
    end

    def self.authorize_and_remember(key_code)
      authorizer = self.prepare_authorizer
      user_id = "default"

      authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: key_code, base_url: OOB_URI
      )
    end

    def self.authorize
      authorizer = self.prepare_authorizer
      user_id = "default"
      credentials = authorizer.get_credentials user_id

      if credentials.nil?
        MeetupController::show_message({type: :danger, message: "Please go to: <host>/admin/meetups in the admin interface of the website and renew the authorization of the calendar api."})
        # TODO(Schau): NO EXCEPTIONS shall be raised for the USER show message instead!
        # raise "Please go to: <host>/admin/meetups in the admin interface of the website and renew the authorization of the calendar api."
      end
      credentials
    end

    def self.get_path_authorized(path, args = {})
      client = HTTPClient.new
      token_store = Google::Auth::Stores::DbTokenStore.new
      loaded_token = token_store.load("meetup")
      if !loaded_token.nil?
        current_tokens = JSON.parse(loaded_token)
        request_uri = "https://api.meetup.com" + path.to_s
        request_query_hash = args.merge({"access_token" => current_tokens["access_token"]})
        begin
          retries ||= 0
          result = client.request("GET", request_uri, request_query_hash)
          parsed_path = JSON.parse(result.nil? ? "" : result.body)
        rescue => ex
          puts "Exception: " + ex.message.to_s
          # exception ... just assume the token needs refreshing...
          credentials_path = AuthCredential.expand_env(ENV['GOOGLE_CALENDAR_JSON'].to_s)
          meetup_credentials = File.open credentials_path.to_s do |f|
            json = f.read
            all_credentials = MultiJson.load json
            all_credentials["meetup"]
          end
          request_uri = "https://secure.meetup.com/oauth2/access"
          request_query_hash = {"client_id": meetup_credentials["client_id"], "client_secret": meetup_credentials["client_secret"], "grant_type": "refresh_token", "refresh_token": "#{current_tokens["refresh_token"]}"}
          begin
            response = JSON.parse(client.post_content(request_uri, request_query_hash))
          rescue => ex
            # puts "Exception: " + ex.message.to_s
            # puts "Authorization not possible. Was authentication revoked for this app?"
            # TODO(Schau): NO EXCEPTIONS shall be raised for the USER show message instead!
            MeetupController::show_message({type: :danger, message: "Authorization not possible. Was authentication revoked for this app? Exception was: #{ex.message}"})
          end

          if !response.nil?
            token_store.store("meetup", {"auth_id": "meetup", "client_id": meetup_credentials["client_id"], "access_token": response["access_token"], "refresh_token": response["refresh_token"], "scope": "", "expiration_time_millis": response["expires_in"] * 1000}.to_json.to_s)
          end

          retry if (retries += 1) < 3
        end
        parsed_path
      else
        # raise "To access this page you need to have authenticated the Meetup API successfully."
        # TODO(Schau): NO EXCEPTIONS shall be raised for the USER show message instead!
        MeetupController::show_message({type: :danger, message: "To access this path you need to have authenticated the Meetup API successfully."})
      end
    end

    def self.gather_meetups
      @meetups = Meetup.all
      group_ids = @meetups.map { |mup| mup.group_id }

      upcoming_events = MeetupsCalendarSyncer.get_path_authorized("/find/upcoming_events", {"page": 200})
      upcoming_events = upcoming_events.nil? ? [] : upcoming_events["events"]
      upcoming_events_of_groups = upcoming_events.select{|e| !e["group"].nil? && group_ids.include?(e["group"]["id"])}

      grouped_upcoming_events = upcoming_events_of_groups.group_by{|e| e["group"]["id"]}
      # NOTE(Schau): Very likely i will be able to refactor this to be more clear.
      limited_upcoming_events = Hash[grouped_upcoming_events.map{|k, v| [k, v.select{|e| Time.at(Rational(e["time"], 1000)) > Time.now}.sort_by{|e| e["time"]}.take(2)]}].select{|k, v| v.any?}
      listed_upcoming_events = limited_upcoming_events.map{|k, v| v.first}
    end

    def self.sync_meetups_to_calendar(listed_upcoming_events)
      calendar_service = Google::Apis::CalendarV3::CalendarService.new
      calendar_service.client_options.application_name = APPLICATION_NAME
      calendar_service.authorization = authorize

      @test_result = []

      listed_upcoming_events.each{ |e|
        location = e.key?('venue') ?
          "#{e['venue']['name'] != e['venue']['address_1'] ?
            e['venue']['name'] + ', ' :
            ''}
            #{e['venue']['address_1']}, #{e['venue']['city']}, #{e['venue']['localized_country_name']}" :
              e.key?('event_url') ? e['event_url'] :
          ""

        new_event_hash = {
          id: Digest::MD5.hexdigest(e['id']),
          summary: e['name'],
          location: location,
          description: e['description'] + (defined?(e['link']) ? "\nLink: " + e['link'] : ""),
          start: {
            date_time: DateTime.parse(Time.at(Rational(e['time'], 1000)).to_s).to_s,
            time_zone: Time.zone.name
          },
          end: {
            date_time: DateTime.parse(Time.at(Rational(e['time'] + e['duration'], 1000)).to_s).to_s,
            time_zone: Time.zone.name
          },
        }

        new_event = Google::Apis::CalendarV3::Event.new(new_event_hash)
        begin
          calendar_service.update_event('primary', new_event.id, new_event)
          @test_result[@test_result.length] = "Updated event: #{new_event.summary}"
        rescue
          begin
            calendar_service.insert_event('primary', new_event)
            @test_result[@test_result.length] = "Created event: #{new_event.summary}"
          rescue => ex
              @test_result[@test_result.length] = "An exception occurred while updating or inserting events."
              puts "Exception: " + ex.message
          end
        end
      }
    end
  end
end