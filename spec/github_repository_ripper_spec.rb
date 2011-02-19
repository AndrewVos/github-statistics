require File.join(File.dirname(__FILE__), '..', 'lib', 'github_repository_ripper')

describe GitHubRepositoryRipper do

  before :each do
    file = mock(:file)
    file.stub!(:write)
    File.stub!(:open).and_yield(file)

    GitHubRepositoryRipper.stub!(:sleep)

    GitHubRepositoryRipper.stub!(:puts)
  end

  describe ".rip_repositories" do

    before :each do
      @languages = ["language1", "language2"]
      @pages_to_rip = 2

      @json = <<-JSON
        {"repositories":[
          {"type":"repo","open_issues":1,"forks":3,"language":"Ruby","url":"https://github.com/rsim/ruby-plsql","has_issues":true,"homepage":"","has_downloads":true,"pushed":"2010/12/10 04:05:40 -0800","fork":false,"pushed_at":"2010/12/10 04:05:40 -0800","followers":38,"created_at":"2008/04/19 07:49:12 -0700","score":0.3126592,"size":296,"private":false,"created":"2008/04/19 07:49:12 -0700","name":"ruby-plsql","owner":"rsim","has_wiki":true,"watchers":38,"username":"rsim","description":"ruby-plsql gem provides simple Ruby API for calling Oracle PL/SQL procedures. It could be used both for accessing Oracle PL/SQL API procedures in legacy applications as well as it could be used to create PL/SQL unit tests using Ruby testing libraries."}
        ]}
      JSON

      @repositories = [{:user_id => "rsim", :repository => "ruby-plsql"}]
      @all_repositories = []
      (1..(@pages_to_rip* @languages.size)).each { @all_repositories << @repositories[0] }

      GitHubRepositoryRipper.stub!(:get_repositories).exactly(@pages_to_rip * @languages.size).times.and_return(@repositories)
    end

    it "rips all languages" do
      expected_messages = []
      @languages.each do |language|
        (1..@pages_to_rip).each do |page|
          expected_messages.push([language, page])
        end
      end
      GitHubRepositoryRipper.should_receive(:get_repositories).exactly(@pages_to_rip * @languages.size).times do |language, page|
        expected_messages.delete([language, page])
      end
      GitHubRepositoryRipper.rip_repositories(@languages, @pages_to_rip)
      expected_messages.size.should == 0
    end

    it "converts the data to yaml" do
      YAML.should_receive(:dump).with(@all_repositories)
      GitHubRepositoryRipper.rip_repositories(@languages, @pages_to_rip)
    end

    it "writes the yaml to a file" do
      YAML.should_receive(:dump).with(@all_repositories).and_return("yaml!")
      file = mock(:file)
      File.should_receive(:open).with('repositories.yml', 'w').and_yield(file)
      file.should_receive(:write).with("yaml!")
      GitHubRepositoryRipper.rip_repositories(@languages, @pages_to_rip)
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

    it "writes out the page and language" do
      GitHubRepositoryRipper.should_receive(:puts).with("ruby page 1")
      GitHubRepositoryRipper.get_repositories("ruby", 1)
    end

    it "should get the url" do
      Net::HTTP.should_receive(:get).once.with(@uri).and_return(@json)
      GitHubRepositoryRipper.get_repositories("ruby", 1)
    end

    it "parses the json and returns repository information" do
      Net::HTTP.should_receive(:get).once.with(@uri).and_return(@json)
      GitHubRepositoryRipper.get_repositories("ruby", 1).should == [
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
        GitHubRepositoryRipper.get_repositories("ruby", 1)
      end

      it "sleeps for a second if it gets a rate limit exceeded response" do
        GitHubRepositoryRipper.should_receive(:sleep).with(1).once
        GitHubRepositoryRipper.get_repositories("ruby", 1)
      end

    end

    context "with two rate limit exceeded responses and one valid response" do

      before :each do
        rate_limit_exceeded = %{{"error":["Rate Limit Exceeded for 127.0.0.1"]}}
        Net::HTTP.stub!(:get).and_return(rate_limit_exceeded, rate_limit_exceeded, @json)
      end

      it "tries multiple times if it gets a rate limit exceeded response" do
        Net::HTTP.should_receive(:get).with(@uri).exactly(3).times
        GitHubRepositoryRipper.get_repositories("ruby", 1)
      end

    end

  end

end
