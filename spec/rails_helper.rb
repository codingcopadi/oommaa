# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
# require 'support/factory_girl'
require 'vcr'
require 'webmock/rspec'
require 'database_cleaner'
require 'devise'

# Add additional requires below this line. Rails is not loaded until this point!
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!
ActiveJob::Base.queue_adapter = :test

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Devise::TestHelpers, type: :controller
  config.include DeviseSpecHelper, type: :controller
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.before(:all) do
    # NOTE FIXME
    # each time VCR cassettes need some change you must remove all of them, take
    # a new token at https://developers.facebook.com/tools/explorer/ and replace this
    @facebook_token = "EAACEdEose0cBABkrqiqPYNC34cW9f4jxaDLkeHm8KSMG2NgYZC5a2292xLQDZCKnA0tMgfX1NZCrMa0gP411rndl2FCFD6FHmt6zbzj9nYC8hv8scg9oZCDfxUEKewD19AgodHBL3VqnEpmqVKn5qGWr51gjvJSkfY3m3TLvJzkVJYX7HGIm"
    @facebook_page_id = "961278360606211" # a page with few posts
    @facebook_page_term = "Dallas Cowboys Fans"
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
