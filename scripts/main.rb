current_curriculum_word_counts =
  `./scripts/current_curriculum_wordcount.sh`
    .split("\n").map do |line|
  count, word = line.split(" ")
  [word, count.to_i]
end.to_h

draft_curriculum_word_counts =
  `./scripts/draft_curriculum_wordcount.sh`
    .split("\n").map do |line|
  count, word = line.split(" ")
  [word, count.to_i]
end.to_h
