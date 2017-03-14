module SolidusSocial
  OAUTH_PROVIDERS = [
    %w(Facebook facebook),
    %w(Twitter twitter),
    %w(Github github),
    %w(Google google_oauth2),
    %w(Amazon amazon)
  ]

  class Engine < Rails::Engine
    engine_name 'solidus_social'

    config.autoload_paths += %W(#{config.root}/lib)

    initializer 'solidus_social.environment', before: 'spree.environment' do
      Spree::SocialConfig = Spree::SocialConfiguration.new
    end

    initializer 'solidus_social.decorate_spree_user' do
      next unless Rails.application.respond_to?(:reloader)

      Rails.application.reloader.after_class_unload do
        # Reload and decorate the spree user class immediately after it is
        # unloaded so that it is available to devise when loading routes
        load File.join(__dir__, '../../app/models/spree/user_decorator.rb')
      end
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end

  # Setup all OAuth providers
  def self.init_provider(provider)
    return unless ActiveRecord::Base.connection.table_exists?('spree_authentication_methods')
    key, secret = nil
    Spree::AuthenticationMethod.where(environment: ::Rails.env).each do |auth_method|
      next unless auth_method.provider == provider
      key = auth_method.api_key
      secret = auth_method.api_secret
      Rails.logger.info("[Spree Social] Loading #{auth_method.provider.capitalize} as authentication source")
    end
    setup_key_for(provider.to_sym, key, secret)
  end

  def self.setup_key_for(provider, key, secret)
    Devise.setup do |config|
      config.omniauth provider, key, secret, setup: true
    end
  end
end

module OmniAuth
  module Strategies
    class Facebook < OAuth2
      MOBILE_USER_AGENTS =  'palm|blackberry|nokia|phone|midp|mobi|symbian|chtml|ericsson|minimo|' \
                            'audiovox|motorola|samsung|telit|upg1|windows ce|ucweb|astel|plucker|' \
                            'x320|x240|j2me|sgh|portable|sprint|docomo|kddi|softbank|android|mmp|' \
                            'pdxgw|netfront|xiino|vodafone|portalmmm|sagem|mot-|sie-|ipod|up\\.b|' \
                            'webos|amoi|novarra|cdm|alcatel|pocket|ipad|iphone|mobileexplorer|' \
                            'mobile'
      def request_phase
        options[:scope] ||= 'email'
        options[:info_fields] ||= 'email'
        options[:display] = mobile_request? ? 'touch' : 'page'
        super
      end

      def mobile_request?
        ua = Rack::Request.new(@env).user_agent.to_s
        ua.downcase =~ Regexp.new(MOBILE_USER_AGENTS)
      end
    end
  end
end
