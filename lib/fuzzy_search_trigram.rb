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
    return {:conditions => "0 = 1"} unless trigrams

    # The SQL expression for calculating fuzzy_score.
    # Has to be used multiple times because some databases (i.e. Postgres)
    # do not support HAVING on named SELECT fields.
    # Possible TODO: Restore old average thing from the original code; the point
    # of that was to prefer short matches when given short query strings.
    # (i.e. "ama" should rank "Amad" higher than "Amalamadingdongwitcherydoo")
    # The average was between:
    # the number of trigrams in the query that matched the record, and
    # the number of trigrams in the record that matched the query!
    fuzzy_score_expr = "((count(*)*100.0)/#{trigrams.size})"
#    fuzzy_score_expr = "(((count(*)*100.0)/#{trigrams.size}) + " +
#    "((count(*)*100.0)/(SELECT count(*) FROM fuzzy_search_trigrams WHERE " +
#    "rec_id = #{q.i(type.table_name)}.#{q.i(type.primary_key)} AND " +
#    "fuzzy_search_type_id = #{q.v(type.send(:fuzzy_type_id))})))/2.0"

    search_result = connection.select_rows(
      "SELECT rec_id, count(*) FROM #{i(table_name)} " +
      "WHERE token IN (#{trigrams.map{|t| v(t)}.join(',')}) " +
      "AND fuzzy_search_type_id = #{v(type.send(:fuzzy_type_id))} " +
      "GROUP by rec_id " +
      "ORDER BY count(*) DESC " +
      "LIMIT #{v(type.send(:fuzzy_search_limit))}"
    )
    return {:conditions => "0 = 1"} if search_result.empty?

    static_sql_union = search_result.map{|rec_id, count|
      "SELECT #{v(rec_id)} AS fuzzy_search_rec_id, #{v(count)} AS fuzzy_search_score"
    }.join(" UNION ");

    return {
      :joins => "INNER JOIN (#{static_sql_union}) ON " +
                "fuzzy_search_rec_id = #{i(type.table_name)}.#{i(type.primary_key)}",
      :order => "fuzzy_search_score DESC"
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
