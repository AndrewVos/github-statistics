require File.join(File.dirname(__FILE__), 'lib', 'github_repository_ripper')
require File.join(File.dirname(__FILE__), 'lib', 'github_commit_ripper')

desc "Rip repository data"
task :rip_repositories do
  languages = ['C', 'C#', 'C++', 'Java', 'JavaScript', 'PHP', 'Python', 'Ruby']
  pages_to_rip = 30
  GitHubRepositoryRipper.rip_repositories(languages, pages_to_rip)
end

desc "Rip all commits from all repositories"
task :rip_all_commits do
  repositories = YAML.load_file('repositories.yml')
  GitHubCommitRipper.rip_all_commits(repositories)
end
