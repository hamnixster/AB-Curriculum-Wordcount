current_curriculum_word_counts =
  `./scripts/current_curriculum_wordcount.sh`
    .split("\n").map do |line|
  count, word = line.split(" ")
  [word, count.to_i]
end.to_h

current_curriculum_words = current_curriculum_word_counts.keys
current_curriculum_overall_word_count =
  current_curriculum_word_counts.values.sum

current_curriculum_word_counts =
  current_curriculum_word_counts.map do |word, count|
  [word,
   [
     count,
     (count/current_curriculum_overall_word_count.to_f)
   ]
  ]
end.to_h

draft_curriculum_word_counts =
  `./scripts/draft_curriculum_wordcount.sh`
    .split("\n").map do |line|
  count, word = line.split(" ")
  [word, count.to_i]
end.to_h

draft_curriculum_words = draft_curriculum_word_counts.keys
draft_curriculum_overall_word_count =
  draft_curriculum_word_counts.values.sum

draft_curriculum_word_counts =
  draft_curriculum_word_counts.map do |word, count|
  [word,
   [
     count,
     (count/draft_curriculum_overall_word_count.to_f)
   ]
  ]
end.to_h

shared_words = draft_curriculum_words.intersection(current_curriculum_words)
removed_words = current_curriculum_words - draft_curriculum_words
added_words = draft_curriculum_words - current_curriculum_words

shared_word_counts =
  current_curriculum_word_counts
    .select { |word, _| shared_words.include?(word) }
    .map do |word, value|
  draft_value = draft_curriculum_word_counts[word]
  [word,
   [
     value.first,                                # count of word in current_curriculum
     draft_value.first,                          # count of word in draft_curriculum
     value.last,                                 # percent of total words in current_curriculum
     draft_value.last,                           # percent of total words in draft_curriculum
     (draft_value.last - value.last)/value.last  # percent change, curriculum size adjusted
   ]
  ]
end.to_h

removed_word_counts =
  current_curriculum_word_counts
    .select { |word, _| removed_words.include?(word) }
    .map do |word, value|
  [word,
   [
     value.first,                        # count of word in current_curriculum
     0,                                  # count of word in draft_curriculum
     value.last,                         # percent of total words in current_curriculum
     0.00,                               # percent of total words in draft_curriculum
     -1.00                               # percent change, curriculum size adjusted
   ]
  ]
end.to_h

added_word_counts =
  draft_curriculum_word_counts
    .select { |word, _| added_words.include?(word) }
    .map do |word, value|
  [word,
   [
     0,                                 # count of word in current_curriculum
     value.first,                       # count of word in draft_curriculum
     0.00,                              # percent of total words in current_curriculum
     value.last,                        # percent of total words in draft_curriculum
     9999999999.99                      # percent change, curriculum size adjusted
   ]
  ]
end.to_h

final_table =
  {}.merge(shared_word_counts, added_word_counts, removed_word_counts)
    .sort_by do |_, values|
    [values[4], values[3], -values[2]]
end

require 'csv'
csv_header = [
  'word',
  'Usage Count in Current Curriculum',
  'Usage Count in Draft Curriculum',
  'Percent of total words in Current Curriculum',
  'Percent of total words in Draft Curriculum',
  'Percent change from Current to Draft Curriculum',
]

CSV.open("word_shift.csv", "w") do |csv|
  csv << csv_header
  final_table.each do |word, values|
    usage_current, usage_draft, usage_p_current, usage_p_draft, shift = values
    csv << [word, usage_current, usage_draft, usage_p_current, usage_p_draft, shift]
  end
end

STOPWORDS = File.read("scripts/stopwords.txt").split("\n")

# Filter words if:
# they have less than 4 letters
# they have at least 3 consecutive digits
# they appear less than 5 times in both curricula
# the word appears in stopwords
def filter_word?(word, values)
  return true unless word
  word = word.strip
  word.length < 4 ||
    word =~ /\d{3}/ ||
    (values[0] < 5 && values[1] < 5 ) ||
    STOPWORDS.include?(word)
end

CSV.open("filtered_word_shift.csv", "w") do |csv|
  csv << csv_header
  final_table
    .reject { |word, values| filter_word?(word, values) }
    .each do |word, values|
    usage_current, usage_draft, usage_p_current, usage_p_draft, shift = values
    csv << [word, usage_current, usage_draft, usage_p_current, usage_p_draft, shift]
  end
end

most_removed =
  final_table
    .reject { |word, values| filter_word?(word, values) }
    .reject { |word, values| values[4] > 0 } # just reduced/removed
    .map do |word, values|
  [word, values[2] - values[3]]
end.sort_by(&:last).reverse.to_h
most_removed_min = most_removed.values.min
most_removed = most_removed.map { |word, value| [word, (value/most_removed_min).to_i] }.to_h

File.open('most_removed.txt', "w") do |f|
  lines = []
  most_removed.each do |word, v|
    v.times { lines << "#{word}\n" }
  end
  lines.shuffle.each { |l| f << l }
end

most_added =
  final_table
    .reject { |word, values| filter_word?(word, values) }
    .reject { |word, values| values[4] < 0 } # just added/expanded
    .map do |word, values|
  [word, values[3] - values[2]]
end.sort_by(&:last).reverse.to_h
most_added_min = most_added.values.min
most_added = most_added.map { |word, value| [word, (value/most_added_min).to_i] }.to_h

File.open('most_added.txt', "w") do |f|
  lines = []
  most_added.each do |word, v|
    v.times { lines << "#{word}\n" }
  end
  lines.shuffle.each { |l| f << l }
end
