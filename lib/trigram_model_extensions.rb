require 'activerecord-import'

module FuzzySearch
  module TrigramModelExtensions
    def set_target_class(cls)
      class_attribute :target_class, inheritable_accessor: true
      self.target_class = cls
    end

    def rebuild_index
      reset_column_information
      delete_all
      target_class.find_each do |rec|
        # Maybe can make this more efficient by updating trigrams for
        # batches of records...
        update_trigrams(rec)
      end
    end

    def params_for_search(search_term, opts = {})
      trigrams = FuzzySearch::split_trigrams(search_term)
      # No results for empty search string
      return {:conditions => "0 = 1"} unless trigrams and !trigrams.empty?

      subset = nil
      if opts[:subset]
        if (
        opts[:subset].size == 1 &&
        opts[:subset].keys.first == target_class.fuzzy_search_subset_property
        )
          subset = opts[:subset].values.first.to_i
          opts.delete(:subset)
        else
          # TODO Test me
          raise "Invalid subset argument #{opts[:subset]}"
        end
      end

      unless opts.empty?
        # TODO Test me
        raise "Invalid options: #{opts.keys.join(",")}"
      end

      # Retrieve the IDs of the matching items
      search_result = connection.select_rows(
        "SELECT rec_id, count(*) FROM #{i(table_name)} " +
        (connection.adapter_name.downcase == 'mysql' ?
          "IGNORE INDEX (index_#{table_name}_on_rec_id) " : ""
        ) +
        "WHERE token IN (#{trigrams.map{|t| v(t)}.join(',')}) " +
        (subset ? "AND subset = #{subset} " : "") +
        "GROUP by rec_id " +
        "ORDER BY count(*) DESC " +
        "LIMIT #{target_class.send(:fuzzy_search_limit)}"
      )
      return {:conditions => "0 = 1"} if search_result.empty?

      # Perform a join between the target table and a fake table of matching ids
      static_sql_union = search_result.map{|rec_id, count|
        "SELECT #{v(rec_id)} AS id, #{count} AS score"
      }.join(" UNION ");
      primary_key_expr = "#{i(target_class.table_name)}.#{i(target_class.primary_key)}"
      return {
        :joins => "INNER JOIN (#{static_sql_union}) AS fuzzy_search_results ON " +
                  "fuzzy_search_results.id = #{primary_key_expr}",
        :order => "fuzzy_search_results.score DESC"
      }
    end

    def update_trigrams(rec)
      delete_trigrams(rec)

      values = target_class.fuzzy_search_properties.map{|p| rec.send(p)}
      values = values.select{|p| p and p.respond_to?(:to_s)}
      trigrams = FuzzySearch::split_trigrams(values)

      subset_prop = target_class.fuzzy_search_subset_property
      subset = subset_prop ? rec.send(subset_prop) : 0

      # Ar-extensions import, much much faster than individual creates
      self.import(
        [:subset, :token, :rec_id],
        trigrams.map{|t| [subset, t, rec.id]},
        :validate => false
      )
    end

    def delete_trigrams(rec)
      delete_all(:rec_id => rec.id)
    end

    private

    # Quote SQL identifier (i.e. table or column name)
    def i(s)
      connection.quote_column_name(s)
    end

    # Quote SQL value (i.e. a string or number)
    def v(s)
      connection.quote(s)
    end
  end
end
