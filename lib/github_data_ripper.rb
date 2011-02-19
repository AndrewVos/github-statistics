require 'net/http'
require 'uri'
require 'json'

class GitHubDataRipper

  class << self

    def rip_data
      ['C#', 'C++', 'Python', 'Ruby'].each do |language|
        (1..30).each do |page|
          get_repositories(language, page)
        end
      end
    end

    def get_repositories(language, page)
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
