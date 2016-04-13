# Quantify coverage
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

if RUBY_VERSION >= '2.0.0'
  require 'byebug'
elsif RUBY_VERSION >= '1.9.0'
  require 'debugger'
end

# load the library
require 'koala'

# Support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# set up our testing environment
# load testing data and (if needed) create test users or validate real users
KoalaTest.setup_test_environment!

BEACH_BALL_PATH = File.join(File.dirname(__FILE__), "fixtures", "beach.jpg")
