require 'yaml'

require File.join(File.dirname(__FILE__), 'lib', 'github_repository_ripper')
require File.join(File.dirname(__FILE__), 'lib', 'github_commit_ripper')

LANGUAGES = ['C', 'C#', 'C++', 'Java', 'JavaScript', 'PHP', 'Python', 'Ruby']

namespace :rip do

  desc "Rip all repositories"
  task :repositories do
    pages_to_rip = 30
    GitHubRepositoryRipper.rip_repositories(LANGUAGES, pages_to_rip)
  end

  desc "Rip all commits"
  task :commits do
    repositories = YAML.load_file('repositories.yml')
    GitHubCommitRipper.rip_all_commits(repositories)
  end

end

namespace :stats do

  desc "Shows all profanity in the messages"
  task :profanity do
    words = %w{shit piss fuck cunt cocksucker motherfucker tits zomg omg wtf}.join("|")
    system %{egrep -h '#{words}' commit*.yml | replace "  :message: " ""}
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

