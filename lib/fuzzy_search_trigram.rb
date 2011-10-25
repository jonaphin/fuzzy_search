class FuzzySearchTrigram < ActiveRecord::Base
  belongs_to :fuzzy_search_type

  def self.rebuild_index(type)
    delete_all(:fuzzy_search_type_id => type.send(:fuzzy_type_id))
    type.find_each do |rec|
      update_trigrams(rec)
    end
  end

  def self.params_for_search(type, search_term)
    trigrams = FuzzySearch::split_trigrams(search_term)
    # No results for empty search string
    return {:conditions => "0 = 1"} unless trigrams and !trigrams.empty?

    # Retrieve the IDs of the matching items
    search_result = connection.select_rows(
      "SELECT rec_id, count(*) FROM #{i(table_name)} " +
      "WHERE token IN (#{trigrams.map{|t| v(t)}.join(',')}) " +
      "AND fuzzy_search_type_id = #{v(type.send(:fuzzy_type_id))} " +
      "GROUP by rec_id " +
      "ORDER BY count(*) DESC " +
      "LIMIT #{v(type.send(:fuzzy_search_limit))}"
    )
    return {:conditions => "0 = 1"} if search_result.empty?

    # Perform a join between the target table and a fake table of matching ids
    static_sql_union = search_result.map{|rec_id, count|
      "SELECT #{v(rec_id)} AS id, #{v(count)} AS score"
    }.join(" UNION ");
    return {
      :joins => "INNER JOIN (#{static_sql_union}) AS fuzzy_search_results ON " +
                "fuzzy_search_results.id = #{i(type.table_name)}.#{i(type.primary_key)}",
      :order => "fuzzy_search_results.score DESC"
    }
  end

  def self.update_trigrams(rec)
    delete_trigrams(rec)

    props = rec.class.fuzzy_search_properties.map{|p| rec.send(p)}
    props = props.select{|p| p and p.respond_to?(:to_s)}
    trigrams = FuzzySearch::split_trigrams(props)

    # Ar-extensions import, much much faster than individual creates
    type_id = rec.class.send(:fuzzy_type_id)
    import(
      [:token, :rec_id, :fuzzy_search_type_id],
      trigrams.map{|t| [t, rec.id, type_id]},
      :validate => false
    )
  end

  def self.delete_trigrams(rec)
    delete_all(
      :rec_id => rec.id,
      :fuzzy_search_type_id => rec.class.send(:fuzzy_type_id)
    )
  end

  private

  # Quote SQL identifier (i.e. table or column name)
  def self.i(s)
    connection.quote_column_name(s)
  end

  # Quote SQL value (i.e. a string or number)
  def self.v(s)
    connection.quote(s)
  end
end
