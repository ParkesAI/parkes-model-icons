# frozen_string_literal: true

module Parkes
  module ModelIcons
    module Helper
      # Unknown names intentionally return nil so the application can render its
      # own neutral fallback. No markup, file path or HTML attributes are accepted.
      def model_icon_tag(name, size: 16, css_class: nil)
        unless size.is_a?(Integer) && (1..1024).cover?(size)
          raise ArgumentError, "Icon size must be an integer from 1 to 1024"
        end
        unless css_class.nil? || css_class.is_a?(String)
          raise ArgumentError, "Icon css_class must be a string or nil"
        end
        return unless ModelIcons.available?(name)

        icon = ModelIcons.fetch(name)
        paths = safe_join(icon.fetch(:paths).map { |attributes| tag.path(**attributes) })
        # String.new removes SafeBuffer status: caller attributes are always escaped.
        tag.svg(paths, **icon.fetch(:attributes), width: size, height: size,
          class: css_class.nil? ? nil : String.new(css_class),
          "aria-hidden": "true", focusable: "false")
      end

      # For asset consumers only. An <img> cannot inherit the page's text colour;
      # use model_icon_tag for theme-aware rendering.
      def model_icon_path(name)
        image_path(ModelIcons.fetch(name).fetch(:asset))
      end
    end
  end
end
