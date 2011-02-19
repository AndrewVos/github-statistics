require 'net/http'
require 'uri'
require 'yaml'
require 'json'

class GitHubCommitRipper

  class << self

    def rip_all_commits(repositories)
      repositories.each_index do |index|
        puts "Repository #{index+1} of #{repositories.size}"
        rip_commits(repositories[index])
      end
    end

    def rip_commits(repository)
      path = "commits[#{repository[:user_id]}.#{repository[:repository]}].yml"
      commits = []
      page = 1
      if File.exist?(path)
        return if File.size(path) > 0
      end
      loop do
        break if page == 11
        puts "Commit page #{page}"
        url = %{http://github.com/api/v2/json/commits/list/#{repository[:user_id]}/#{repository[:repository]}/master/?page=#{page}}
        json = get_json(url)
        break if json == nil
        json = JSON.parse(json)
        commits << json["commits"].map { |commit| { :language => repository[:language], :message => commit["message"] } }
        page = page + 1
      end
      commits.flatten!

      File.open(path, 'w') do |file|
        begin
        file.write(YAML::dump(commits))
        rescue
          puts "Error writing #{repository[:user_id]}/#{repository[:repository]}"
        end
      end
      commits
    end

    def get_json(url)
      uri = URI.parse(url)
      json = nil
      while json == nil
        json = Net::HTTP.get(uri)
        json = nil if json =~ /{"error":\["Rate Limit Exceeded for \d+.\d+.\d+.\d+"\]}/
        return nil if json =~ /{"error":"Not Found"}/
        sleep(1) if json == nil
      end
      json
    end

  end

end
