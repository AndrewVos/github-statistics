require File.join(File.dirname(__FILE__), 'lib', 'github_repository_ripper')

desc "Rip repository data"
task :rip_repositories do
  languages = ['C', 'C#', 'C++', 'Java', 'JavaScript', 'PHP', 'Python', 'Ruby']
  pages_to_rip = 30
  GitHubRepositoryRipper.rip_repositories(languages, pages_to_rip)
end

desc "Rip all commits from all repositories"
task :rip_commits do
  yaml = YAML.load_file('repositories.yml')
  yaml.each do |repository|
    GitHubCommitRipper.rip_commits(repository[:user_id], repository[:name])
  end
end
