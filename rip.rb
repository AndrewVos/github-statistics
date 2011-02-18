require 'net/http'
require 'uri'

['C#', 'C++', 'Python', 'Ruby'].each do |language|
  (1..30).each do |page|
    url = %{http://github.com/api/v2/json/repos/search/+?type=Repositories&language=#{language}&start_page=#{page}}
    puts url
    json = Net::HTTP.get(URI.parse(url))
    filename = %{#{language}-page#{page}.json}
    File.open(filename, 'w') do |file|
      file.write(json)
    end
  end
end
