require File.expand_path('../boot', __FILE__)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
# require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
# require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

class GCDisabler
  def initialize(app)
    @app = app
  end

  def call(env)
    GC.start
    GC.disable
    response = @app.call(env)
    GC.enable
    response
  end
end

module RpRails
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # To profile only Rails App:
    # config.middleware.use Rack::RubyProf, path: '/tmp/rails_profile'
    # To profile middleware also:
    config.middleware.insert_before Rack::Runtime, Rack::RubyProf, path: '/tmp/rails_profile'
    config.middleware.insert_before Rack::RubyProf, GCDisabler
  end
end
