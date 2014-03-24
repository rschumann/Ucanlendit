require 'zeus/rails'

require File.expand_path('../test/helper_modules', __FILE__)
include TestHelpers

class CustomPlan < Zeus::Rails

  # def my_custom_command
  #  # see https://github.com/burke/zeus/blob/master/docs/ruby/modifying.md
  # end

  def cucumber_environment


    # Ensure sphinx directories exist for the test environment
    ThinkingSphinx::Test.init
    
    # Stop Sphinx if it was already running
    ThinkingSphinx::Test.stop

    # Start Sphinx
    # With Zeus we don't care if it stays running afterwards. It's anyway restarted next time Zeus starts
    # And keeping it running makes running new tests much faster
    ThinkingSphinx::Test.start

    # Populate db with default data
    require 'database_cleaner'
    DatabaseCleaner.clean_with(:truncation)
    load_default_test_data_to_db_before_suite
    load_default_test_data_to_db_before_test
  end
end

Zeus.plan = CustomPlan.new
