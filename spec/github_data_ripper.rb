require 'net/http'
require 'uri'

class GitHubDataRipper
  class << self
    def rip_data
      ['C#', 'C++', 'Python', 'Ruby'].each do |language|
        (1..30).each do |page|
          rip_url %{http://github.com/api/v2/json/repos/search/+?type=Repositories&language=#{language}&start_page=#{page}}
        end
      end
    end

    def rip_url(url)
      uri = URI.parse(url)
      json = Net::HTTP.get(uri)
    end
  end
end

describe GitHubDataRipper do
  describe ".rip_data" do
    it "rips all languages" do
      expected_urls = []
      ['C#', 'C++', 'Python', 'Ruby'].each do |language|
        (1..30).each do |page|
          expected_urls.push %{http://github.com/api/v2/json/repos/search/+?type=Repositories&language=#{language}&start_page=#{page}}
        end
      end
      GitHubDataRipper.should_receive(:rip_url).exactly(120).times do |url|
        expected_urls.delete(url)
      end
      GitHubDataRipper.rip_data
      expected_urls.size.should == 0
    end
  end

  describe ".rip_url" do
    before :each do
      @url = "http://www.example.org"
      @uri = URI.parse(@url)
    end

    it "should parse the url" do
      URI.should_receive(:parse).once.with(@url).and_return(@uri)
      GitHubDataRipper.rip_url(@url)
    end

    it "should get the url" do
      URI.should_receive(:parse).once.with(@url).and_return(@uri)
      Net::HTTP.should_receive(:get).once.with(@uri).and_return("json")
      GitHubDataRipper.rip_url(@url)
    end

    it "should return the json" do
      URI.should_receive(:parse).once.with(@url).and_return(@uri)
      Net::HTTP.should_receive(:get).once.with(@uri).and_return("my json stuff")
      GitHubDataRipper.rip_url(@url).should == "my json stuff"
    end
  end
end
