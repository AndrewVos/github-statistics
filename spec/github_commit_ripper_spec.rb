require File.join(File.dirname(__FILE__), '..', 'lib', 'github_commit_ripper')

describe GitHubCommitRipper do

  before :each do
    @repository = { :language => "ruby", :user_id => "bob", :repository => "dotfiles" }
    @repositories = [@repository]
    GitHubCommitRipper.stub!(:puts)
    @file = mock(:file)
    @file.stub!(:write)
    File.stub!(:open).and_yield(@file)
  end

  describe ".rip_all_commits" do

    it "calls .rip_commits" do
      GitHubCommitRipper.should_receive(:rip_commits).with(@repository).and_return("some json")
      GitHubCommitRipper.rip_all_commits(@repositories)
    end

    it "converts commits to yaml" do
      commits = [
        { :language => "ruby", :message => "fix ruby rev-list implementation not handling array of refs"},
        { :language => "ruby", :message => "update History for argv fixes" }
      ]
      GitHubCommitRipper.should_receive(:rip_commits).with(@repository).and_return(commits)
      YAML.should_receive(:dump).with(commits)
      GitHubCommitRipper.rip_all_commits(@repositories)
    end

    it "outputs information about the current progress" do
      GitHubCommitRipper.should_receive(:rip_commits).with(@repository).and_return("some json")
      GitHubCommitRipper.should_receive(:puts).with("Repository 1 of 1")
      GitHubCommitRipper.rip_all_commits(@repositories)
    end

    it "writes commit data out to a file" do
     commits = [
        { :language => "ruby", :message => "fix ruby rev-list implementation not handling array of refs"},
        { :language => "ruby", :message => "update History for argv fixes" }
      ]
      GitHubCommitRipper.should_receive(:rip_commits).with(@repository).and_return(commits)
      File.should_receive(:open).with('commits.yml', 'w').and_yield(@file)
      expected_yaml = YAML::dump(commits)
      @file.should_receive(:write).with(expected_yaml)
      GitHubCommitRipper.rip_all_commits(@repositories)
    end

  end

  describe ".rip_commits" do

    before :each do
      @valid_json = <<-JSON
        {"commits":[
          {"parents":[{"id":"ffac829d5c552985d266f328277f96e176aad4a7"}],"author":{"name":"Ryan Tomayko","login":"rtomayko","email":"rtomayko@gmail.com"},"url":"/mojombo/grit/commit/fdbead12e2060af12d43ddd384b8f64f53683281","id":"fdbead12e2060af12d43ddd384b8f64f53683281","committed_date":"2011-02-11T09:41:05-08:00","authored_date":"2011-02-11T09:41:05-08:00","message":"fix ruby rev-list implementation not handling array of refs","tree":"4f63efa9b4268b898575e9602ced2c134e469d8c","committer":{"name":"Ryan Tomayko","login":"rtomayko","email":"rtomayko@gmail.com"}},
          {"parents":[{"id":"358df98aa0ada3c0bab7bda3aa52a38e1adb0dfb"}],"author":{"name":"Ryan Tomayko","login":"rtomayko","email":"rtomayko@gmail.com"},"url":"/mojombo/grit/commit/ffac829d5c552985d266f328277f96e176aad4a7","id":"ffac829d5c552985d266f328277f96e176aad4a7","committed_date":"2011-02-11T08:50:01-08:00","authored_date":"2011-02-11T08:50:01-08:00","message":"update History for argv fixes","tree":"4d27deaf224d8bbca836446cd1a76c140b66aa77","committer":{"name":"Ryan Tomayko","login":"rtomayko","email":"rtomayko@gmail.com"}}
        ]}
      JSON
    end

    it "calls .get_json with different pages until it returns nil" do
      (1..3).each do |page|
        expected_url = %{http://github.com/api/v2/json/commits/list/bob/dotfiles/master/?page=#{page}}
        json = @valid_json
        json = nil if page == 3
        GitHubCommitRipper.should_receive(:get_json).with(expected_url).once.and_return(json)
      end
      GitHubCommitRipper.rip_commits(@repository)
    end

    it "returns commit data" do
      GitHubCommitRipper.should_receive(:get_json).and_return(@valid_json, nil)
      GitHubCommitRipper.rip_commits(@repository).should == [
        { :language => "ruby", :message => "fix ruby rev-list implementation not handling array of refs"},
        { :language => "ruby", :message => "update History for argv fixes" }
      ]
    end

  end

  describe ".get_json" do

    before :each do
      @url = "http://www.example.com"
      @uri = URI.parse(@url)
      @expected_json = "Here's your json good Sir!"
      @rate_limit_exceeded = %{{"error":["Rate Limit Exceeded for 127.0.0.1"]}}
      GitHubCommitRipper.stub!(:sleep)
      URI.should_receive(:parse).with(@url).once.and_return(@uri)
    end

    it "gets the json" do
      Net::HTTP.should_receive(:get).with(@uri).once.and_return(@expected_json)
      GitHubCommitRipper.get_json(@url).should == @expected_json
    end

    context "with some rate limit exceeded responses" do

      before :each do
        Net::HTTP.stub!(:get).with(@uri).and_return(@rate_limit_exceeded, @rate_limit_exceeded, @expected_json)
      end

      it "retries if it gets a rate limit exceeded response" do
        GitHubCommitRipper.get_json(@url).should == @expected_json
      end

      it "sleeps before each retry" do
        GitHubCommitRipper.should_receive(:sleep).with(1).twice
        GitHubCommitRipper.get_json(@url)
      end

    end

    context "no json response" do

      before :each do
        Net::HTTP.stub!(:get).with(@uri).once.and_return("")
      end

      it "returns nil if there is no json" do
        GitHubCommitRipper.get_json(@url).should == nil
      end

    end

  end

end
