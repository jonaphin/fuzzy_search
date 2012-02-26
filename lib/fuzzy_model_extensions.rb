require 'set'

module FuzzySearch
  module FuzzyModelExtensions
    def self.included(base)
      base.class_attribute :fuzzy_search_properties, instance_accessor: true
      base.class_attribute :fuzzy_search_limit, instance_accessor: true
      base.class_attribute :fuzzy_search_subset_property, instance_accessor: true
      
      base.fuzzy_search_properties = []
      base.fuzzy_search_limit = 25
      base.fuzzy_search_subset_property = nil

      base.extend ClassMethods
    end

    module ClassMethods
      def fuzzy_searchable_on(*properties)
        # TODO: Complain if fuzzy_searchable_on is called more than once
        # TODO: Complain if no properties were given
        options = properties.last.is_a?(Hash) ? properties.pop : {}
        class_attribute :fuzzy_search_properties, instance_accessor: true
        self.fuzzy_search_properties = properties
        if options[:subset_on]
          class_attribute :fuzzy_search_subset_property, instance_accessor: true
          self.fuzzy_search_subset_property = options[:subset_on]
          options.delete(:subset_on)
        end

        unless options.empty?
          # TODO Test me
          raise "Invalid options: #{options.keys.join(",")}"
        end

        scope :fuzzy_search_scope, lambda { |words|
          fuzzy_search_scope_with_opts(words, {})
        }
        scope :fuzzy_search_scope_with_opts, lambda { |words, opts|
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
