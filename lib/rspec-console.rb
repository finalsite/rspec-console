module RSpecConsole
  autoload :ConfigCache,    'rspec-console/config_cache'
  autoload :RSpecState,     'rspec-console/rspec_state'
  autoload :Runner,         'rspec-console/runner'
  autoload :Pry,            'rspec-console/pry'

  class << self; attr_accessor :before_run_callbacks; end
  self.before_run_callbacks = []

  def self.run(*args)
    Runner.run(args)
  end

  def self.before_run(&hook)
    self.before_run_callbacks << hook
  end

  Pry.setup if defined?(::Pry)

  # We only want the test env
  before_run do
    if defined?(Rails) && !(Rails.env =~ /test/)
      raise 'Please run in test mode (run `rails console test`).'
    end
  end

  # Emit warning when reload cannot be called, or call reload!
  before_run do
    if defined?(Rails)
      if Rails.application.config.cache_classes
        STDERR.puts <<-MSG.gsub(/^ {10}/, '')
          \033[31m[ WARNING ]\033[0m
          Rails's cache_classes must be turned off.
          Turn it off in config/environments/test.rb:

            Rails.application.configure do
              config.cache_classes = false
            end

          Otherwise, code relading does not work.
        MSG
      else
        Rails.application.reloader.reload!
      end
    end
  end

  # Reloading FactoryGirl if necessary
  before_run { FactoryGirl.reload if defined?(FactoryGirl) }

  # This is needed to avoid problem explained at
  # https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#rails-preloaders-and-rspec
  before_run { FactoryBot.reload if defined?(FactoryBot) }

  # Clear Faker gem unique
  before_run { Faker::Name.unique.clear }
  before_run { Faker::Lorem.unique.clear }
  before_run { Faker::Number.unique.clear }
  before_run { Faker::Internet.unique.clear }
end
