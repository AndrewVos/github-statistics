require 'net/http'
require 'uri'

def rip_data
  ['C#', 'C++', 'Python', 'Ruby'].each do |language|
    (1..30).each do |page|
      url = %{http://github.com/api/v2/json/repos/search/+?type=Repositories&language=#{language}&start_page=#{page}}
      puts url
      json = get_json(url)
      filename = %{#{language}-page#{page}.json}
      File.open(filename, 'w') do |file|
        file.write(json)
      end
    end
  end
end

def get_json(url)
  json = nil
  while json == nil
    json = Net::HTTP.get(URI.parse(url))
    if json =~ /{"error":["Rate Limit Exceeded for \d+.\d+.\d+.\d+"]}/
      puts "Rate limit exceeded. Sleeping for 1 second"
      json = nil
      sleep(1000)
    end
  end
  json
end

rip_data
