# small helper method for live testing
module KoalaTest

  class << self
    attr_accessor :oauth_token, :app_id, :secret, :app_access_token, :code, :session_key
    attr_accessor :oauth_test_data, :subscription_test_data, :search_time
  end
    
  # Test setup
  
  def self.setup_test_environment!
    setup_rspec
    
    unless ENV['LIVE']
      # By default the Koala specs are run using stubs for HTTP requests,
      # so they won't fail due to Facebook-imposed rate limits or server timeouts.
      #
      # However as a result they are more brittle since
      # we are not testing the latest responses from the Facebook servers.
      # To be certain all specs pass with the current Facebook services, 
      # run LIVE=true bundle exec rake spec.
      Koala.http_service = Koala::MockHTTPService
      KoalaTest.setup_test_data(Koala::MockHTTPService::TEST_DATA)
    else
      # Runs Koala specs through the Facebook servers
      # using data for a real app
      live_data = YAML.load_file(File.join(File.dirname(__FILE__), '../fixtures/facebook_data.yml'))
      KoalaTest.setup_test_data(live_data)

      # allow live tests with different adapters
      adapter = ENV['ADAPTER'] || "typhoeus"# use Typhoeus by default if available
      begin
        require adapter
        Faraday.default_adapter = adapter.to_sym
      rescue LoadError
        puts "Unable to load adapter #{adapter}, using Net::HTTP."
      end
      
      Koala.http_service.http_options[:beta] = true if ENV["beta"] || ENV["BETA"]

      # use a test user unless the developer wants to test against a real profile
      unless token = KoalaTest.oauth_token
        KoalaTest.setup_test_users
      else
        KoalaTest.validate_user_info(token)
      end
    end
  end
  
  def self.setup_rspec
    # set up a global before block to set the token for tests
    # set the token up for
    RSpec.configure do |config|
      config.before :each do
        @token = KoalaTest.oauth_token
        Koala::Utils.stub(:deprecate) # never fire deprecation warnings
      end

      config.after :each do
        # clean up any objects posted to Facebook
        if @temporary_object_id && !KoalaTest.mock_interface?
          api = @api || (@test_users ? @test_users.graph_api : nil)
          raise "Unable to locate API when passed temporary object to delete!" unless api

          # wait 10ms to allow Facebook to propagate data so we can delete it
          sleep(0.01)

          # clean up any objects we've posted
          result = (api.delete_object(@temporary_object_id) rescue false)
          # if we errored out or Facebook returned false, track that
          puts "Unable to delete #{@temporary_object_id}: #{result} (probably a photo or video, which can't be deleted through the API)" unless result
        end
      end
    end
  end

  def self.setup_test_data(data)
    # make data accessible to all our tests
    self.oauth_test_data = data["oauth_test_data"]
    self.subscription_test_data = data["subscription_test_data"]
    self.oauth_token = data["oauth_token"]
    self.app_id = data["oauth_test_data"]["app_id"]
    self.app_access_token = data["oauth_test_data"]["app_access_token"]
    self.secret = data["oauth_test_data"]["secret"]
    self.code = data["oauth_test_data"]["code"]
    self.session_key = data["oauth_test_data"]["session_key"]
    
    # fix the search time so it can be used in the mock responses
    self.search_time = data["search_time"] || (Time.now - 3600).to_s
  end

  def self.testing_permissions
    "read_stream, publish_stream, user_photos, user_videos, read_insights"
  end
  
  def self.setup_test_users
    print "Setting up test users..."
    @test_user_api = Koala::Facebook::TestUsers.new(:app_id => self.app_id, :secret => self.secret)

    RSpec.configure do |config|
      config.before :suite do
        # before each test module, create two test users with specific names and befriend them
        KoalaTest.create_test_users
      end
      
      config.after :suite do
        # after each test module, delete the test users to avoid cluttering up the application
        KoalaTest.destroy_test_users
      end
    end

    puts "done."
  end

  def self.create_test_users
    begin
      @live_testing_user = @test_user_api.create(true, KoalaTest.testing_permissions, :name => KoalaTest.user1_name)
      @live_testing_friend = @test_user_api.create(true, KoalaTest.testing_permissions, :name => KoalaTest.user2_name)
      @test_user_api.befriend(@live_testing_user, @live_testing_friend)
      self.oauth_token = @live_testing_user["access_token"]
    rescue Exception => e
      Kernel.warn("Problem creating test users! #{e.message}")
      raise
    end    
  end
  
  def self.destroy_test_users
    [@live_testing_user, @live_testing_friend].each do |u|
      puts "Unable to delete test user #{u.inspect}" if u && !(@test_user_api.delete(u) rescue false)
    end
  end

  def self.validate_user_info(token)
    print "Validating permissions for live testing..."
    # make sure we have the necessary permissions
    api = Koala::Facebook::API.new(token)
    perms = api.fql_query("select #{testing_permissions} from permissions where uid = me()")[0]
    perms.each_pair do |perm, value|
      if value == (perm == "read_insights" ? 1 : 0) # live testing depends on insights calls failing
        puts "failed!\n" # put a new line after the print above
        raise ArgumentError, "Your access token must have the read_stream, publish_stream, and user_photos permissions, and lack read_insights.  You have: #{perms.inspect}"
      end
    end
    puts "done!"
  end
  
  # Info about the testing environment
  def self.real_user?
    !(mock_interface? || @test_user)
  end

  def self.test_user?
    !!@test_user_api
  end

  def self.mock_interface?
    Koala.http_service == Koala::MockHTTPService
  end

  # Data for testing
  def self.user1
    test_user? ? @live_testing_user["id"] : "koppel"
  end

  def self.user1_id
    test_user? ? @live_testing_user["id"] : 2905623
  end

  def self.user1_name
    "Alex"
  end

  def self.user2
    test_user? ? @live_testing_friend["id"] : "lukeshepard"
  end

  def self.user2_id
    test_user? ? @live_testing_friend["id"] : 2901279
  end

  def self.user2_name
    "Luke"
  end

  def self.page
    "contextoptional"
  end

end
