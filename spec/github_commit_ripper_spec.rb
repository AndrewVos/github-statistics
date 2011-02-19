require 'net/http'
require 'uri'

class GitHubCommitRipper

  class << self

    def rip_commits(user_id, repository, page)
      url = %{http://github.com/api/v2/json/commits/list/#{user_id}/#{repository}/master/?page=#{page}}
      get_json(url)
    end

    def get_json(url)
      uri = URI.parse(url)
      json = nil
      while json == nil
        json = Net::HTTP.get(uri)
        json = nil if json =~ /\{"error":\["Rate Limit Exceeded for \d+.\d+.\d+.\d+"\]\}/
        sleep(1) if json == nil
      end
      json
    end

  end

end

describe GitHubCommitRipper do

  describe ".rip_commits" do

    it "calls .get_json with the expected url" do
      user_id = "bill"
      repository = "vimfiles"
      page = 1
      expected_json = "some handy json"
      url = %{http://github.com/api/v2/json/commits/list/#{user_id}/#{repository}/master/?page=#{page}}
      GitHubCommitRipper.should_receive(:get_json).with(url).and_return(expected_json)
      GitHubCommitRipper.rip_commits(user_id, repository, page).should == expected_json
    end

  end

  describe ".get_json" do

    before :each do
      @url = "http://www.example.org"
      @uri = URI.parse(@url)
      @expected_json = "Here's your json good Sir!"
      @rate_limit_exceeded = %{{"error":["Rate Limit Exceeded for 127.0.0.1"]}}
      GitHubCommitRipper.stub!(:sleep)
    end

    it "gets the json" do
      URI.should_receive(:parse).with(@url).once.and_return(@uri)
      Net::HTTP.should_receive(:get).with(@uri).once.and_return(@expected_json)
      GitHubCommitRipper.get_json(@url).should == @expected_json
    end

    it "retries if it gets a rate limit exceeded response" do
      @expected_json = "Here's your json good Sir!"
      URI.should_receive(:parse).with(@url).once.and_return(@uri)
      Net::HTTP.should_receive(:get).with(@uri).once.and_return(@rate_limit_exceeded, @rate_limit_exceeded, @expected_json)
      GitHubCommitRipper.get_json(@url).should == @expected_json
    end

    it "sleeps before each retry" do
      URI.should_receive(:parse).with(@url).once.and_return(@uri)
      Net::HTTP.should_receive(:get).with(@uri).once.and_return(@rate_limit_exceeded, @rate_limit_exceeded, @expected_json)
      GitHubCommitRipper.should_receive(:sleep).with(1).twice
      GitHubCommitRipper.get_json(@url).should == @expected_json
    end

  end

end
