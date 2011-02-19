require File.join(File.dirname(__FILE__), 'lib', 'github_data_ripper')

desc "Rip repository data"
task :rip_repositories do
  languages = ['C', 'C#', 'C++', 'Java', 'JavaScript', 'PHP', 'Python', 'Ruby']
  pages_to_rip = 30
  GitHubRepositoryRipper.rip_repositories(languages, pages_to_rip)
end
