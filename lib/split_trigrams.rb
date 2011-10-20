module FuzzySearch
  def self.split_trigrams(s)
    s = s.join(" ") if s.is_a?(Array)
    return [] unless s and s.respond_to?(:to_s)
    words = s.to_s.strip.split(/[\s\-]+/)
    trigrams = Set.new
    words.each do |w|
      chars = w.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').downcase.strip
      chars = " " + chars + " "
      (0..chars.length-3).each do |idx|
        trigrams << chars[idx,3].to_s
      end
    end
    return trigrams.to_a
  end
end
