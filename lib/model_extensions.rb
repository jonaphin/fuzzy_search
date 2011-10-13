module FuzzySearch
  module ModelExtensions
    def self.included(base)
      base.extend ClassMethods

      base.write_inheritable_attribute :fuzzy_search_properties, []
      base.class_inheritable_reader :fuzzy_search_properties

      base.write_inheritable_attribute :fuzzy_search_threshold, 5
      base.class_inheritable_reader :fuzzy_search_treshold
    end

    module ClassMethods
      def fuzzy_searchable_on(*properties)
        # TODO: Complain if fuzzy_searchable_on is called more than once
        write_inheritable_attribute :fuzzy_search_properties, properties
        has_many :fuzzy_search_trigrams, :as => :rec, :dependent => :destroy
        after_save :update_fuzzy_search_trigrams!
        named_scope :fuzzy_search_scope, lambda { |words| generate_fuzzy_search_scope_params(words) }
        extend WordNormalizerClassMethod unless respond_to? :normalize
        include InstanceMethods
      end

      def fuzzy_search(words)
        # TODO: If fuzzy_search_scope doesn't exist, provide a useful error
        fuzzy_search_scope(words).all
      end

      private

      def generate_fuzzy_search_scope_params(words)
        return {} unless words != nil
        words = words.strip.to_s.split(/[\s\-]+/) unless words.instance_of? Array
        return {} unless words.size > 0

        trigrams = []
        words.each do |w|
          word = ' ' + normalize(w) + ' '
          word_as_chars = word.mb_chars
          trigrams << (0..word_as_chars.length-3).collect {|idx| word_as_chars[idx,3].to_s}
        end
        trigrams = trigrams.flatten.uniq

        # Transform the list of columns in the searchable entity into 
        # a SQL fragment like:
        # "table_name.id, table_name.field1, table_name.field2, ..."
        entity_fields = columns.map {|col| table_name + "." + col.name}.join(", ")

        # The SQL expression for calculating fuzzy_weight
        # Has to be used multiple times because some databases (i.e. Postgres) do not support HAVING on named SELECT fields
        # TODO: See if we can't get the count(*) out of here, that's a non-trivial operation in some databases
        fuzzy_weight_expr = "(((count(*)*100.0)/#{trigrams.size}) + " +
          "((count(*)*100.0)/(SELECT count(*) FROM fuzzy_search_trigrams WHERE rec_id = #{table_name}.#{primary_key} AND rec_type = '#{class_name}')))/2.0"

        # TODO: Optimize this query. In a large trigram table, this is going to go through a lot of dead ends.
        # Maybe I need to just bite the bullet and learn how to do procedures? That would break cross-database compatibility, though...
        return {
          :select => "#{fuzzy_weight_expr} AS fuzzy_weight, #{entity_fields}",
          :joins => ["LEFT OUTER JOIN fuzzy_search_trigrams ON fuzzy_search_trigrams.rec_id = #{table_name}.#{primary_key}"],
          :conditions => ["fuzzy_search_trigrams.token IN (?) AND rec_type = '#{class_name}'", trigrams],
          :group => "#{table_name}.#{primary_key}",
          :order => "fuzzy_weight DESC",
          :having => "#{fuzzy_weight_expr} >= #{fuzzy_search_threshold}"
        }
      end
    end

    module WordNormalizerClassMethod
      def normalize(word)
        word.downcase
      end
    end

    module InstanceMethods
      def update_fuzzy_search_trigrams!
        self.class.connection.execute "DELETE FROM fuzzy_search_trigrams WHERE rec_id = #{self.id} AND rec_type = '#{self.class.class_name}'"

        # to avoid double entries
        tokens = []
        self.class.fuzzy_props.each do |prop|
          prop_value = send(prop)
          next if prop_value.nil?
          # split the property into words (which are separated by whitespaces)
          # and generate the trigrams for each word
          prop_value.to_s.split(/[\s\-]+/).each do |p|
            # put a space in front and at the end to emphasize the endings
            word = ' ' + self.class.normalize(p) + ' '
            word_as_chars = word.mb_chars
            (0..word_as_chars.length - 3).each do |idx|
              token = word_as_chars[idx, 3].to_s
              tokens << token unless tokens.member?(token)
            end
          end
        end

        # Ugh, this is bringing me back to my PHP days. But this is still better than N queries.
        q = "INSERT INTO fuzzy_search_trigrams(token, rec_id, rec_type) VALUES "
        q += tokens.map{|t| "(#{t},#{self.id},'#{self.class.class_name}')"}.join(",")
        self.class.connection.execute q
      end
    end
  end
end
