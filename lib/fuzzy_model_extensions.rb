module FuzzySearch
  module ModelExtensions
    def self.included(base)
      base.extend ClassMethods

      base.write_inheritable_attribute :fuzzy_search_properties, []
      base.class_inheritable_reader :fuzzy_search_properties

      base.write_inheritable_attribute :fuzzy_search_threshold, 5
      base.class_inheritable_reader :fuzzy_search_threshold
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

      def rebuild_fuzzy_search_index!
        FuzzySearchTrigram.delete_all(:rec_type => self.class.name)
        all.each do |rec|
          rec.update_fuzzy_search_trigrams!
        end
      end

      private

      def generate_fuzzy_search_scope_params(words)
        no_results = {:conditions => "0 = 1"}
        return no_results unless words != nil
        words = words.strip.to_s.split(/[\s\-]+/) unless words.instance_of? Array
        return no_results unless words.size > 0

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

        # The SQL expression for calculating fuzzy_score
        # Has to be used multiple times because some databases (i.e. Postgres) do not support HAVING on named SELECT fields
        # TODO: See if we can't get the count(*) out of here, that's a non-trivial operation in some databases
        fuzzy_score_expr = "(((count(*)*100.0)/#{trigrams.size}) + " +
          "((count(*)*100.0)/(SELECT count(*) FROM fuzzy_search_trigrams WHERE rec_id = #{table_name}.#{primary_key} AND rec_type = '#{name}')))/2.0"

        # TODO: Optimize this query. In a large trigram table, this is going to go through a lot of dead ends.
        # Maybe I need to just bite the bullet and learn how to do procedures? That would break cross-database compatibility, though...
        return {
          :select => "#{fuzzy_score_expr} AS fuzzy_score, #{entity_fields}",
          :joins => ["LEFT OUTER JOIN fuzzy_search_trigrams ON fuzzy_search_trigrams.rec_id = #{table_name}.#{primary_key}"],
          :conditions => ["fuzzy_search_trigrams.token IN (?) AND rec_type = '#{name}'", trigrams],
          :group => "#{table_name}.#{primary_key}",
          :order => "fuzzy_score DESC",
          :having => "#{fuzzy_score_expr} >= #{fuzzy_search_threshold}"
        }
      end
    end

    module WordNormalizerClassMethod
      def normalize(word)
        word.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').downcase.to_s
      end
    end

    module InstanceMethods
      def update_fuzzy_search_trigrams!
        FuzzySearchTrigram.delete_all(:rec_id => self.id, :rec_type => self.class.name)

        # to avoid double entries
        tokens = []
        self.class.fuzzy_search_properties.each do |prop|
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

        FuzzySearchTrigram.import(
          [:token, :rec_id, :rec_type],
          tokens.map{|t| [t, self.id, self.class.name]},
          :validate => false
        )
      end
    end
  end
end
