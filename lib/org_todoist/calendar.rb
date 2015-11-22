module OrgToggl
  class Calendar
    attr_reader :cal

    def initialize client_id, client_sec, calendar_id
      @cal = Google::Calendar.new(:client_id     => client_id,
                                  :client_secret => client_sec,
                                  :calendar      => calendar_id,
                                  :redirect_url  => "urn:ietf:wg:oauth:2.0:oob")
    end

    def authorize refresh_token=ENV['CAL_REFRESH_TOKEN']
      if refresh_token
        cal.login_with_refresh_token(refresh_token)
      else
        interactive_authorize
      end
    end

    # --------- for setup --------------------------------------------------
    def interactive_authorize
      # A user needs to approve access in order to work with their calendars.
      puts "Visit the following web page in your browser and approve access."
      puts cal.authorize_url
      system("open '#{cal.authorize_url}'")
      puts "\nCopy the code that Google returned and paste it here:"

      # Pass the ONE TIME USE access code here to login and get a refresh token that you can use for access from now on.
      refresh_token = cal.login_with_auth_code( $stdin.gets.chomp )

      puts "\nMake sure you SAVE YOUR REFRESH TOKEN so you don't have to prompt the user to approve access again."
      puts "your refresh token is:\n\t#{refresh_token}\n"
      puts "Press return to continue"
      $stdin.gets.chomp

      puts "Do you want to try GET and POST? (y/n)"
      try_api = $stdin.gets.chomp
      if try_api == 'y'
        test_refresh_token
      end
    end

    def test_refresh_token
      event = cal.create_event do |e|
        e.title = 'A Cool Event'
        e.start_time = Time.now
        e.end_time = Time.now + (60 * 60) # seconds * min
      end
      puts event

      event = cal.find_or_create_event_by_id(event.id) do |e|
        e.title = 'An Updated Cool Event'
        e.end_time = Time.now + (60 * 60 * 2) # seconds * min * hours
      end
      puts event

      # All events
      puts cal.events

      # Query events
      puts cal.find_events('Cool')
    end
  end
end
