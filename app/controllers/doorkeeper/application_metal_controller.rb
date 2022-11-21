module Doorkeeper
  class ApplicationMetalController < Doorkeeper.configuration.base_metal_controller.constantize
    MODULES = [
      ActionController::Instrumentation,
      AbstractController::Rendering,
      ActionController::Rendering,
      ActionController::Renderers::All,
      Helpers::Controller
    ].freeze

    MODULES.each do |mod|
      include mod
    end

    ActiveSupport.run_load_hooks(:doorkeeper_metal_controller, self)
  end
end
