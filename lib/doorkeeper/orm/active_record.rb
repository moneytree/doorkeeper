# frozen_string_literal: true

require "active_support/lazy_load_hooks"

require "doorkeeper/orm/active_record/stale_records_cleaner"

module Doorkeeper
  module Orm
    module ActiveRecord
      def self.initialize_models!
        lazy_load do
          require "doorkeeper/orm/active_record/access_grant"
          require "doorkeeper/orm/active_record/access_token"
          require "doorkeeper/orm/active_record/application"

          if Doorkeeper.configuration.active_record_options[:establish_connection]
            Doorkeeper::Orm::ActiveRecord.models.each do |model|
              options = Doorkeeper.configuration.active_record_options[:establish_connection]
              model.establish_connection(options)
            end
          end
        end
      end

      def self.initialize_application_owner!
        lazy_load do
          require "doorkeeper/models/concerns/ownership"

          Doorkeeper.configuration.application_model.send :include, Doorkeeper::Models::Ownership
        end
      end

      def self.lazy_load(&block)
        ActiveSupport.on_load(:active_record, {}, &block)
      end

      def self.models
        [
          Doorkeeper.configuration.access_grant_model,
          Doorkeeper.configuration.access_token_model,
          Doorkeeper.configuration.application_model,
        ]
      end
    end
  end
end
