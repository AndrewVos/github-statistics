require 'net/http'
require 'uri'

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
      json
    end

  end

end

describe GitHubDataRipper do

  describe ".rip_data" do

    it "rips all languages" do
      expected_messages = []
      ['C#', 'C++', 'Python', 'Ruby'].each do |language|
        (1..30).each do |page|
          expected_messages.push([language, page])
        end
      end
      GitHubDataRipper.should_receive(:get_repositories).exactly(120).times do |language, page|
        expected_messages.delete([language, page])
      end
      GitHubDataRipper.rip_data
      expected_messages.size.should == 0
    end

  end

  describe ".get_repositories" do

    before :each do
      @url = %{http://github.com/api/v2/json/repos/search/+?type=Repositories&language=ruby&start_page=1}
      @uri = URI.parse(@url)
      URI.should_receive(:parse).once.with(@url).and_return(@uri)
    end

    it "should get the url" do
      Net::HTTP.should_receive(:get).once.with(@uri).and_return("json")
      GitHubDataRipper.get_repositories("ruby", 1)
    end

    it "should return the json" do
      Net::HTTP.should_receive(:get).once.with(@uri).and_return("my json stuff")
      GitHubDataRipper.get_repositories("ruby", 1).should == "my json stuff"
    end

    context "with one rate limit exceeded response and one valid response" do

      before :each do
        Net::HTTP.stub!(:get).and_return(%{{"error":["Rate Limit Exceeded for 127.0.0.1"]}}, "some json")
      end

      it "tries again if it gets a rate limit exceeded response" do
        Net::HTTP.should_receive(:get).with(@uri).twice
        GitHubDataRipper.get_repositories("ruby", 1)
      end

      it "sleeps for a second if it gets a rate limit exceeded response" do
        GitHubDataRipper.should_receive(:sleep).with(1).once
        GitHubDataRipper.get_repositories("ruby", 1)
      end

    end

    context "with two rate limit exceeded responses and one valid response" do

      before :each do
        rate_limit_exceeded = %{{"error":["Rate Limit Exceeded for 127.0.0.1"]}}
        Net::HTTP.stub!(:get).and_return(rate_limit_exceeded, rate_limit_exceeded, "valid json")
      end

      it "tries multiple times if it gets a rate limit exceeded response" do
        Net::HTTP.should_receive(:get).with(@uri).exactly(3).times
        GitHubDataRipper.get_repositories("ruby", 1)
      end

    end

  end

end
