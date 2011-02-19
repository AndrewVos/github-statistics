require File.join(File.dirname(__FILE__), '..', 'lib', 'github_data_ripper')

describe GitHubDataRipper do

  describe ".rip_data" do

    before :each do
      @json = <<-JSON
        {"repositories":[
          {"type":"repo","open_issues":1,"forks":3,"language":"Ruby","url":"https://github.com/rsim/ruby-plsql","has_issues":true,"homepage":"","has_downloads":true,"pushed":"2010/12/10 04:05:40 -0800","fork":false,"pushed_at":"2010/12/10 04:05:40 -0800","followers":38,"created_at":"2008/04/19 07:49:12 -0700","score":0.3126592,"size":296,"private":false,"created":"2008/04/19 07:49:12 -0700","name":"ruby-plsql","owner":"rsim","has_wiki":true,"watchers":38,"username":"rsim","description":"ruby-plsql gem provides simple Ruby API for calling Oracle PL/SQL procedures. It could be used both for accessing Oracle PL/SQL API procedures in legacy applications as well as it could be used to create PL/SQL unit tests using Ruby testing libraries."}
        ]}
      JSON

      @repository = [
        {:user_id => "rsim", :repository => "ruby-plsql"}
      ]

      @all_repositories = []
      (1..120).each { @all_repositories << @repository }
      @all_repositories.flatten!
    end

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

    it "converts the data to yaml" do
      GitHubDataRipper.should_receive(:get_repositories).exactly(120).times.and_return(@repository)
      YAML.should_receive(:dump).with(@all_repositories)
      GitHubDataRipper.rip_data
    end
  end

  describe ".get_repositories" do

    before :each do
      @url = %{http://github.com/api/v2/json/repos/search/+?type=Repositories&language=ruby&start_page=1}
      @uri = URI.parse(@url)
      @json = <<-JSON
        {"repositories":[
          {"type":"repo","open_issues":1,"forks":3,"language":"Ruby","url":"https://github.com/rsim/ruby-plsql","has_issues":true,"homepage":"","has_downloads":true,"pushed":"2010/12/10 04:05:40 -0800","fork":false,"pushed_at":"2010/12/10 04:05:40 -0800","followers":38,"created_at":"2008/04/19 07:49:12 -0700","score":0.3126592,"size":296,"private":false,"created":"2008/04/19 07:49:12 -0700","name":"ruby-plsql","owner":"rsim","has_wiki":true,"watchers":38,"username":"rsim","description":"ruby-plsql gem provides simple Ruby API for calling Oracle PL/SQL procedures. It could be used both for accessing Oracle PL/SQL API procedures in legacy applications as well as it could be used to create PL/SQL unit tests using Ruby testing libraries."},
          {"type":"repo","open_issues":0,"forks":7,"language":"Ruby","url":"https://github.com/richdownie/watircuke","has_issues":true,"homepage":"","has_downloads":true,"pushed":"2010/03/22 17:27:24 -0700","fork":false,"pushed_at":"2010/03/22 17:27:24 -0700","followers":31,"created_at":"2009/06/10 13:34:35 -0700","score":0.40881574,"size":152,"private":false,"created":"2009/06/10 13:34:35 -0700","name":"watircuke","owner":"richdownie","has_wiki":true,"watchers":31,"username":"richdownie","description":"The First Cross-Browser, HTML Element Agnostic, Automated Ruby Testing Framework"}
        ]}
      JSON
      URI.should_receive(:parse).once.with(@url).and_return(@uri)
    end

    it "should get the url" do
      Net::HTTP.should_receive(:get).once.with(@uri).and_return(@json)
      GitHubDataRipper.get_repositories("ruby", 1)
    end

    it "parses the json and returns repository information" do
     Net::HTTP.should_receive(:get).once.with(@uri).and_return(@json)
      GitHubDataRipper.get_repositories("ruby", 1).should == [
        {:user_id => "rsim", :repository => "ruby-plsql"},
        {:user_id => "richdownie", :repository => "watircuke"}
      ]
    end

    context "with one rate limit exceeded response and one valid response" do

      before :each do
        Net::HTTP.stub!(:get).and_return(%{{"error":["Rate Limit Exceeded for 127.0.0.1"]}}, @json)
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
        Net::HTTP.stub!(:get).and_return(rate_limit_exceeded, rate_limit_exceeded, @json)
      end

      it "tries multiple times if it gets a rate limit exceeded response" do
        Net::HTTP.should_receive(:get).with(@uri).exactly(3).times
        GitHubDataRipper.get_repositories("ruby", 1)
      end

    end

  end

end
