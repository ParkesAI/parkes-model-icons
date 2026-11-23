# frozen_string_literal: true

module Parkes
  module ModelIcons
    class Engine < ::Rails::Engine
      initializer "parkes.model_icons.helpers" do
        ActiveSupport.on_load(:action_view) do
          include Parkes::ModelIcons::Helper
        end
      end
    end
  end
end
