require 'net/http'
require 'uri'
require 'json'
require 'yaml'

class GitHubRepositoryRipper

  class << self

    def rip_repositories(languages, pages_to_rip)
      all_repositories = []
      languages.each do |language|
        (1..pages_to_rip).each do |page|
          all_repositories << get_repositories(language, page)
        end
      end
      all_repositories.flatten!
      File.open('repositories.yml', 'w') do |file|
        file.write(YAML.dump(all_repositories))
      end
    end

    def get_repositories(language, page)
      puts %{#{language} page #{page}}
      uri = URI.parse %{http://github.com/api/v2/json/repos/search/+?type=Repositories&language=#{language}&start_page=#{page}}
      json = nil
      while json == nil
        json = Net::HTTP.get(uri)
        if json =~ /\{"error":\["Rate Limit Exceeded for \d+.\d+.\d+.\d+"\]\}/
          json = nil
          sleep(1)
        end
      end
      parsed_json = JSON.parse(json)
      data = []
      parsed_json["repositories"].each do |repository|
        data << {:user_id => repository["username"], :repository => repository["name"]}
      end
      data
    end

  end

end
