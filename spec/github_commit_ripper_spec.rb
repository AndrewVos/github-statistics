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

    it "outputs information about the current progress" do
      GitHubCommitRipper.should_receive(:rip_commits).with(@repository).and_return("some json")
      GitHubCommitRipper.should_receive(:puts).with("Repository 1 of 1")
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
      @commits = [
        { :language => "ruby", :message => "fix ruby rev-list implementation not handling array of refs"},
        { :language => "ruby", :message => "update History for argv fixes" }
      ]
      @output_path = "commits[bob.dotfiles].yml"
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

    it "stops when it has 10 pages" do
      ten_repositories = (1..11).map { |number| @repository }
      GitHubCommitRipper.should_receive(:get_json).exactly(10).times.and_return(@valid_json)
      GitHubCommitRipper.rip_commits(@repository)
    end

    it "returns commit data" do
      GitHubCommitRipper.should_receive(:get_json).and_return(@valid_json, nil)
      GitHubCommitRipper.rip_commits(@repository).should == @commits
    end

    it "outputs information about the current status of ripping" do
      GitHubCommitRipper.should_receive(:get_json).and_return(@valid_json, nil)
      GitHubCommitRipper.should_receive(:puts).with("Commit page 1")
      GitHubCommitRipper.rip_commits(@repository)
    end

    it "writes commit data to file" do
      GitHubCommitRipper.should_receive(:get_json).and_return(@valid_json, nil)
      File.should_receive(:open).with("commits[bob.dotfiles].yml", 'w').and_yield(@file)
      @file.should_receive(:write).with(YAML::dump(@commits))
      GitHubCommitRipper.rip_commits(@repository)
    end

    it "doesn't write to file if the file already exists and is not empty" do
      File.should_receive(:exist?).with(@output_path).and_return(true)
      File.should_receive(:size).with(@output_path).and_return(100)
      GitHubCommitRipper.should_not_receive(:get_json)
      File.should_not_receive(:open)
      @file.should_not_receive(:write)
      GitHubCommitRipper.rip_commits(@repository)
    end

    it "outputs a message if writing the file failed" do
      GitHubCommitRipper.should_receive(:get_json).and_return(@valid_json, nil)
      File.should_receive(:open).with("commits[bob.dotfiles].yml", 'w').and_yield(@file)
      @file.should_receive(:write).and_throw(RuntimeError)
      GitHubCommitRipper.should_receive(:puts).with("Error writing bob/dotfiles")
      GitHubCommitRipper.rip_commits(@repository)
    end

  end

  describe ".get_json" do

    before :each do
      @url = "http://www.example.com"
      @uri = URI.parse(@url)
      @expected_json = "Here's your json good Sir!"
      @rate_limit_exceeded = %{{"error":["Rate Limit Exceeded for 127.0.0.1"]}}
      @error_not_found = %{{"error":"Not Found"}}
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

    context "with error not found response" do

      before :each do
        Net::HTTP.stub!(:get).with(@uri).and_return(@error_not_found)
      end

      it "returns nil if it gets an error not found response" do
        GitHubCommitRipper.get_json(@url).should == nil
      end

    end

  end

end
