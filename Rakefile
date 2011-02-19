require File.join(File.dirname(__FILE__), 'lib', 'github_repository_ripper')
require File.join(File.dirname(__FILE__), 'lib', 'github_commit_ripper')

namespace :rip do

  desc "Rip all repositories"
  task :repositories do
    languages = ['C', 'C#', 'C++', 'Java', 'JavaScript', 'PHP', 'Python', 'Ruby']
    pages_to_rip = 30
    GitHubRepositoryRipper.rip_repositories(languages, pages_to_rip)
  end

  desc "Rip all commits"
  task :commits do
    repositories = YAML.load_file('repositories.yml')
    GitHubCommitRipper.rip_all_commits(repositories)
  end

end

namespace :stats do

  desc "Shows all profanity in the commits"
  task :profanity do
    words = %w{shit piss fuck cunt cocksucker motherfucker tits zomg omg wtf}.join("|")
    system "egrep -h '#{words}' commit*.yml"
  end

end

