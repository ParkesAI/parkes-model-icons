# frozen_string_literal: true

require "nokogiri"

module Parkes
  module ModelIcons
    # This is a deliberately narrow grammar for the four vetted upstream marks,
    # not a sanitizer for arbitrary SVG. New artwork requires explicit review.
    module Svg
      NAMESPACE = "http://www.w3.org/2000/svg"
      ROOT_ATTRIBUTES = %w[fill fill-rule height style viewBox width].freeze
      PATH_ATTRIBUTES = %w[d fill fill-rule clip-rule].freeze
      private_constant :ROOT_ATTRIBUTES, :PATH_ATTRIBUTES

      def self.parse(bytes)
        document = Nokogiri::XML(bytes) { |config| config.strict.nonet }
        root = document.root
        invalid! if document.internal_subset || !root || root.name != "svg"
        invalid! unless root.namespace&.href == NAMESPACE && root.namespace_definitions.size == 1
        invalid! unless root.namespace_definitions.first.prefix.nil?
        invalid! unless document.children.all? { |node| node == root || (node.text? && node.text.strip.empty?) }
        invalid! unless root.attribute_nodes.all? { |attr| !attr.namespace && ROOT_ATTRIBUTES.include?(attr.name) }
        invalid! unless root["viewBox"] == "0 0 24 24"
        invalid! unless %w[currentColor none].include?(root["fill"])
        invalid! if root["fill-rule"] && !%w[evenodd nonzero].include?(root["fill-rule"])
        invalid! unless root["width"] == "1em" && root["height"] == "1em"
        invalid! unless root["style"] == "flex:none;line-height:1"

        paths = []
        root.children.each do |node|
          next if node.text? && node.text.strip.empty?

          invalid! unless node.element? && node.namespace&.href == NAMESPACE && node.namespace_definitions.empty?
          case node.name
          when "title"
            invalid! unless node.attribute_nodes.empty? && node.children.all?(&:text?)
          when "path"
            invalid! unless node.children.empty?
            invalid! unless node.attribute_nodes.all? { |attr| !attr.namespace && PATH_ATTRIBUTES.include?(attr.name) }
            invalid! unless node["d"]&.match?(/\A[MmLlHhVvCcSsQqTtAaZz0-9eE.,+\s-]+\z/)
            invalid! if node["fill"] && !%w[currentColor none].include?(node["fill"])
            %w[fill-rule clip-rule].each do |key|
              invalid! if node[key] && !%w[evenodd nonzero].include?(node[key])
            end
            # A filled shape must inherit currentColor, never a fixed colour.
            invalid! unless (node["fill"] || root["fill"]) == "currentColor"
            paths << node.attribute_nodes.to_h { |attr| [attr.name.to_sym, attr.value.freeze] }.freeze
          else
            invalid!
          end
        end
        invalid! if paths.empty?
        attributes = { xmlns: NAMESPACE, viewBox: root["viewBox"].freeze, fill: root["fill"].freeze }
        attributes[:"fill-rule"] = root["fill-rule"].freeze if root["fill-rule"]
        { attributes: attributes.freeze, paths: paths.freeze }.freeze
      rescue Nokogiri::XML::SyntaxError
        invalid!
      end

      def self.invalid!
        raise ArgumentError, "Bundled icon does not match the vetted SVG grammar"
      end
      private_class_method :invalid!
    end
  end
end
