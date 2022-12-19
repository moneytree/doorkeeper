module Doorkeeper
  module Orm
    module ActiveRecord
      def self.initialize_models!
        require 'doorkeeper/orm/active_record/access_grant'
        require 'doorkeeper/orm/active_record/access_token'
        require 'doorkeeper/orm/active_record/application'

        if Doorkeeper.configuration.active_record_options[:establish_connection]
          Doorkeeper::Orm::ActiveRecord.models.each do |model|
            model.send :establish_connection, Doorkeeper.configuration.active_record_options[:establish_connection]
          end
        end
      end

      def self.initialize_application_owner!
        require 'doorkeeper/models/concerns/ownership'

        Doorkeeper.configuration.application_model.send :include, Doorkeeper::Models::Ownership
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
