require 'set'

module FuzzySearch
  module FuzzyModelExtensions
    def self.included(base)
      {
        :fuzzy_search_properties => [],
        :fuzzy_search_limit => 25,
        :fuzzy_search_subset_property => nil
      }.each do |key, value|
        base.write_inheritable_attribute key, value
        base.class_inheritable_reader key
      end

      base.extend ClassMethods
    end

    module ClassMethods
      def fuzzy_searchable_on(*properties)
        # TODO: Complain if fuzzy_searchable_on is called more than once
        # TODO: Complain if no properties were given
        options = properties.last.is_a?(Hash) ? properties.pop : {}
        write_inheritable_attribute :fuzzy_search_properties, properties
        if options[:subset_on]
          write_inheritable_attribute :fuzzy_search_subset_property, options[:subset_on]
          options.delete(:subset_on)
        end

        unless options.empty?
          # TODO Test me
          raise "Invalid options: #{options.keys.join(",")}"
        end

        named_scope :fuzzy_search_scope, lambda { |words|
          fuzzy_search_scope_with_opts(words, {})
        }
        named_scope :fuzzy_search_scope_with_opts, lambda { |words, opts|
          self::FuzzySearchTrigram.params_for_search(words, opts)
        }
        extend FuzzySearchClassMethods
        include InstanceMethods
        after_save :update_fuzzy_search_trigrams!
        after_destroy :delete_fuzzy_search_trigrams!

        const_set(:FuzzySearchTrigram, Class.new(ActiveRecord::Base))
        self::FuzzySearchTrigram.extend TrigramModelExtensions
        self::FuzzySearchTrigram.set_target_class self
        self::FuzzySearchTrigram.table_name = "#{name.underscore}_fuzzy_search_trigrams"
      end
    end

    module FuzzySearchClassMethods
      def fuzzy_search(words, opts = {})
        fuzzy_search_scope_with_opts(words, opts)
      end

      def rebuild_fuzzy_search_index!
        self::FuzzySearchTrigram.rebuild_index
      end
    end

    module InstanceMethods
      def update_fuzzy_search_trigrams!
        self.class::FuzzySearchTrigram.update_trigrams(self)
      end

      def delete_fuzzy_search_trigrams!
        self.class::FuzzySearchTrigram.delete_trigrams(self)
      end
    end
  end
end
