module FuzzySearch
  module TrigramModelExtensions
    def set_target_class(cls)
      write_inheritable_attribute :target_class, cls
      class_inheritable_reader :target_class
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

    def params_for_search(type, search_term)
      trigrams = FuzzySearch::split_trigrams(search_term)
      # No results for empty search string
      return {:conditions => "0 = 1"} unless trigrams and !trigrams.empty?

      # Retrieve the IDs of the matching items
      search_result = connection.select_rows(
        "SELECT rec_id, count(*) FROM #{i(table_name)} " +
        (connection.adapter_name.downcase == 'mysql' ?
          "USE INDEX (PRIMARY) " : ""
        ) +
        "WHERE token IN (#{trigrams.map{|t| v(t)}.join(',')}) " +
        "GROUP by rec_id " +
        "ORDER BY count(*) DESC " +
        "LIMIT #{type.send(:fuzzy_search_limit)}"
      )
      return {:conditions => "0 = 1"} if search_result.empty?

      # Perform a join between the target table and a fake table of matching ids
      static_sql_union = search_result.map{|rec_id, count|
        "SELECT #{v(rec_id)} AS id, #{count} AS score"
      }.join(" UNION ");
      return {
        :joins => "INNER JOIN (#{static_sql_union}) AS fuzzy_search_results ON " +
                  "fuzzy_search_results.id = #{i(target_class.table_name)}.#{i(target_class.primary_key)}",
        :order => "fuzzy_search_results.score DESC"
      }
    end

    def update_trigrams(rec)
      delete_trigrams(rec)

      props = target_class.fuzzy_search_properties.map{|p| rec.send(p)}
      props = props.select{|p| p and p.respond_to?(:to_s)}
      trigrams = FuzzySearch::split_trigrams(props)

      # Ar-extensions import, much much faster than individual creates
      import(
        [:subscope, :token, :rec_id],
        trigrams.map{|t| [0, t, rec.id]}, # FIXME: Use subscope for something helpful
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
