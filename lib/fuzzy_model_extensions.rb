require 'set'

module FuzzySearch
  module ModelExtensions
    def self.included(base)
      base.extend ClassMethods

      base.write_inheritable_attribute :fuzzy_search_properties, []
      base.class_inheritable_reader :fuzzy_search_properties

      base.write_inheritable_attribute :fuzzy_search_threshold, 5
      base.class_inheritable_reader :fuzzy_search_threshold

      base.write_inheritable_attribute :fuzzy_search_type_id, nil
      base.class_inheritable_reader :fuzzy_search_type_id
    end

    module ClassMethods
      def fuzzy_searchable_on(*properties)
        # TODO: Complain if fuzzy_searchable_on is called more than once
        named_scope :fuzzy_search_scope, lambda { |words|
          generate_fuzzy_search_scope_params(words)
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
        FuzzySearchTrigram.delete_all(:fuzzy_search_type_id => fuzzy_type_id)
        all.each do |rec|
          rec.update_fuzzy_search_trigrams!
        end
      end

      private

      # Retrieve type id, creating it if necessary
      def fuzzy_type_id
        r = fuzzy_search_type_id
        unless r
          r = FuzzySearchType.find_or_create_by_type_name(name)
          write_inheritable_attribute :fuzzy_search_type_id, r
        end
        r
      end

      def generate_fuzzy_search_scope_params(words)
        # Quote SQL identifier (i.e. table or column name)
        def qi(s)
          connection.quote_column_name(s)
        end

        # Quote SQL value (i.e. a string or number)
        def qv(s)
          connection.quote(s)
        end

        trigrams = FuzzySearch::split_trigrams(words)
        # No results for empty search string
        return {:conditions => "0 = 1"} unless trigrams

        # Transform the list of columns in the searchable entity into 
        # a SQL fragment like:
        # "table_name"."id", "table_name"."field1", "table_name"."field2", ...
        entity_fields = columns.map{|col| "#{qi(table_name)}.#{qi(col.name)}"}.join(",")

        # The SQL expression for calculating fuzzy_score.
        # Has to be used multiple times because some databases (i.e. Postgres)
        # do not support HAVING on named SELECT fields.
        fuzzy_score_expr = "((count(*)*100.0)/#{trigrams.size})"

        # TODO: Optimize this query.
        # Perhaps better to search primarily on the trigram table alone, then just
        # return a simple scope that lists ids.
        return {
          :select => "#{fuzzy_score_expr} AS fuzzy_score, #{entity_fields}",
          :joins => "INNER JOIN fuzzy_search_trigrams ON fuzzy_search_trigrams.rec_id = #{qi(table_name)}.#{qi(primary_key)}",
          :conditions => ["fuzzy_search_trigrams.token IN (?) AND fuzzy_search_type_id = ?",
            trigrams, fuzzy_type_id],
          :group => "#{qi(table_name)}.#{qi(primary_key)}",
          :order => "fuzzy_score DESC",
          :having => "#{fuzzy_score_expr} >= #{qv(fuzzy_search_threshold)}"
        }
      end
    end

    module InstanceMethods
      def update_fuzzy_search_trigrams!
        delete_fuzzy_search_trigrams!

        props = self.class.fuzzy_search_properties.map{|p| send(p)}
        props = props.select{|p| p and p.respond_to?(:to_s)}
        trigrams = FuzzySearch::split_trigrams(props)

        FuzzySearchTrigram.import(
          [:token, :rec_id, :fuzzy_search_type_id],
          trigrams.map{|t| [t, self.id, self.class.send(:fuzzy_type_id)]},
          :validate => false
        )
      end

      def delete_fuzzy_search_trigrams!
        FuzzySearchTrigram.delete_all(
          :rec_id => self.id,
          :fuzzy_search_type_id => self.class.send(:fuzzy_type_id)
        )
      end
    end
  end
end
