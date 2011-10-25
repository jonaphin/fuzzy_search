require 'set'

module FuzzySearch
  module FuzzyModelExtensions
    def self.included(base)
      base.extend ClassMethods

      {
        :fuzzy_search_properties => [],
        :fuzzy_search_limit => 25
      }.each do |key, value|
        base.write_inheritable_attribute key, value
        base.class_inheritable_reader key
      end
    end

    module ClassMethods
      def fuzzy_searchable_on(*properties)
        # TODO: Complain if fuzzy_searchable_on is called more than once
        named_scope :fuzzy_search_scope, lambda { |words|
          self::FuzzySearchTrigram.params_for_search(self, words)
        }
        write_inheritable_attribute :fuzzy_search_properties, properties
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
      def fuzzy_search(words)
        fuzzy_search_scope(words).all
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
