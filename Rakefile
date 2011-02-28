require 'yaml'

require File.join(File.dirname(__FILE__), 'lib', 'github_repository_ripper')
require File.join(File.dirname(__FILE__), 'lib', 'github_commit_ripper')

LANGUAGES_TO_SEARCH = ['C', 'csharp', 'C%2B%2B', 'Java', 'JavaScript', 'Perl', 'PHP', 'Python', 'Ruby']

namespace :rip do

  desc "Rip all repositories"
  task :repositories do
    pages_to_rip = 30
    GitHubRepositoryRipper.rip_repositories(LANGUAGES_TO_SEARCH, pages_to_rip)
  end

  desc "Rip all commits"
  task :commits do
    repositories = YAML.load_file('repositories.yml')
    GitHubCommitRipper.rip_all_commits(repositories)
  end

  desc "Write all commits to one big file"
  task :merge_commits do
    all_commits = {}
    Dir.glob('commit*.yml').map do |file|
      puts file
      yaml = YAML.load_file(file)
      next unless yaml
      yaml.each do |commit|
        all_commits[commit[:language]] ||= []
        all_commits[commit[:language]] << commit
      end
    end

    all_commits.keys.each do |language|
      output_path = "language-commits[#{language}].yml"
      puts output_path
      File.delete(output_path) if File.exist?(output_path)
      File.open(output_path, 'w') do |file|
        messages = all_commits[language].map { |commit| { :message => commit[:message] } }
        file.puts(YAML.dump(messages))
      end
    end
  end

end

namespace :stats do

  desc "Shows all profanity in the messages"
  task :profanity do
    words = %w{shit piss fuck cunt cocksucker motherfucker tits}
    #words = %w{wtf omg roflcopter rofl lol zomg}
    #words = %w{hack}
    #words = %w{todo}
    #words = %w{workaround}
    profanity = {}
    commit_message_count = 0
    profanity_count = 0
    messages_with_profanity = []
    word_frequency = {}
    Dir.glob("language-commits*.yml").each do |file|
      language = file.match(/\[(.+)\]/).captures[0]
      profanity[language] ||= 0
      YAML.load_file(file).each do |message|
        message[:message].split(" ").each do |word|
          word.downcase!
          if words.include?(word)
            profanity[language] += 1
            profanity_count += 1
            word_frequency[word] ||= 0
            word_frequency[word] += 1
            messages_with_profanity << message[:message]
          elsif word == ":message:"
            commit_message_count +=1
          end
        end
      end
    end
    File.open('profanity_word_frequency.yml', 'w') do |file|
      file.write(YAML.dump(word_frequency))
    end
    File.open('profanity.yml', 'w') do |file|
      file.write(YAML.dump(messages_with_profanity))
    end
    puts "Keys   " +  profanity.map{|k,v| v}.join(" ")
    puts "Values " +profanity.map{|k,v| k}.join(" ")
    puts profanity
    puts "#{commit_message_count}/#{profanity_count}"
  end

  desc "Show all messages ordered by their frequency"
  task :message_frequency do
    system %{grep -h message commit*.yml | sort | uniq -c | sort -r | replace "  :message: " ""}
  end

  desc "Show all words ordered by their frequency"
  task :word_frequency do
    system <<-COMMAND
      grep message: commit*.yml | replace "  :message: " "" | awk '
      {
        for (i=1;i<=NF;i++)
        count[$i]++
      }
      END {
        for (i in count)
        print count[i], i
      }' $* | sort -rn
    COMMAND
  end

end

