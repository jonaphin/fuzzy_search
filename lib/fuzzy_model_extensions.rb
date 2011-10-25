require 'set'

module FuzzySearch
  module ModelExtensions
    def self.included(base)
      base.extend ClassMethods

      {
        :fuzzy_search_properties => [],
        :fuzzy_search_limit => 25,
        :fuzzy_search_cached_type_id => nil
      }.each do |key, value|
        base.write_inheritable_attribute key, value
        base.class_inheritable_reader key
      end
    end

    module ClassMethods
      def fuzzy_searchable_on(*properties)
        # TODO: Complain if fuzzy_searchable_on is called more than once
        named_scope :fuzzy_search_scope, lambda { |words|
          FuzzySearchTrigram.params_for_search(self, words)
        }

        after_save :update_fuzzy_search_trigrams!
        after_destroy :delete_fuzzy_search_trigrams!

        write_inheritable_attribute :fuzzy_search_properties, properties

        extend FuzzySearchClassMethods
        include InstanceMethods
      end
    end

    module FuzzySearchClassMethods
      def fuzzy_search(words)
        fuzzy_search_scope(words).all
      end

      def rebuild_fuzzy_search_index!
        FuzzySearchTrigram.rebuild_index(self)
      end

      private

      # Retrieve cached fuzzy type id, creating it if necessary
      def fuzzy_type_id
        r = fuzzy_search_cached_type_id
        unless r
          r = FuzzySearchType.find_or_create_by_type_name(name).id
          write_inheritable_attribute :fuzzy_search_cached_type_id, r
        end
        r
      end
    end

    module InstanceMethods
      def update_fuzzy_search_trigrams!
        FuzzySearchTrigram.update_trigrams(self)
      end

      def delete_fuzzy_search_trigrams!
        FuzzySearchTrigram.delete_trigrams(self)
      end
    end
  end
end
