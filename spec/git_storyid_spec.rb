require "spec_helper"
require "fileutils"

describe GitStoryid do

  let(:commands) { []}

  def run(*args)
    GitStoryid.run(*args)
  end

  class ForceQuit < StandardError
  end

  def should_quit_with(expected)
    actual = nil
    GitStoryid.send(:define_method, :quit) do |message|
      actual = message
      raise ForceQuit
    end
    yield
    true.should eq(false)
  rescue ForceQuit
    actual.should_not be_nil
    actual.should == expected

  end


  describe "Pivotal" do

  before(:each) do

    GitStoryid::Configuration.stubs(:load_config_from).
      returns(
        engine: "pivotal",
        api_token: "a2b4e",
        me: "BG",
        project_id: "1234",
    )
    commands = self.commands
    GitStoryid.send(:define_method, :execute) do |*args|
      commands << args
      ""
    end
    GitStoryid.any_instance.stubs(:ensure_changes_stashed!).returns(true)
      GitStoryid.any_instance.stubs(:output).returns(true)

      GitStoryid::PivotalConfiguration.any_instance.stubs(:fetch_all_stories).returns([
        Hashie::Mash.new(
          :deadline => nil,
          :labels => "paypal",
          :accepted_at => nil,
          :id => 44647731,
          :jira_id => nil,
          :estimate => 1,
          :integration_id => nil,
          :owned_by => "Bogdan Gusiev",
          :name => "Strip Default paypal credentials",
          :created_at => DateTime.now,
          :story_type => "feature",
          :other_id => nil,
          :description => "",
          :requested_by => "Dominic Coryell",
          :url => "http://www.pivotaltracker.com/story/show/44647731",
          :attachments => [],
          :project_id => 135657,
          :jira_url => nil,
          :current_state => "finished"
        ),
        Hashie::Mash.new(
          :deadline => nil,
          :labels => "paypal",
          :accepted_at => nil,
          :id => 44647732,
          :jira_id => nil,
          :estimate => 1,
          :integration_id => nil,
          :owned_by => "Bogdan Gusiev",
          :name => "Require pro paypal account for mass payments",
          :created_at => DateTime.now,
          :story_type => "feature",
          :other_id => nil,
          :description => "",
          :requested_by => "Dominic Coryell",
          :url => "http://www.pivotaltracker.com/story/show/44647732",
          :attachments => [],
          :project_id => 135657,
          :jira_url => nil,
          :current_state => "finished"
        )
      ])
  end

  context "when stories exists" do

    it "should commit changes" do
      GitStoryid.any_instance.stubs(:readline).returns('1')
      run("-m",  'Hello world')
      commands.should include(["git", "commit", "-m", "[#44647731] Hello world\n\nFeature: Strip Default paypal credentials"])
    end

    it "should render stories menu correctly" do
      subject.stories_menu.should == <<-EOI
[1] Strip Default paypal credentials
[2] Require pro paypal account for mass payments

EOI
    end

    it "should commit to multiple stories" do
      GitStoryid.any_instance.stubs(:readline).returns('1,2')
      run("-m",  'Hello world')
      commands.should include(
        ["git", "commit", "-m",
          "[#44647731, #44647732] Hello world\n\nFeature: Strip Default paypal credentials\n\nFeature: Require pro paypal account for mass payments"]
      )
    end

    it "should support finishing" do
      GitStoryid.any_instance.stubs(:readline).returns('1')
      run('-f')
      commands.should include(["git", "commit", "-m", "[Finishes #44647731] Feature: Strip Default paypal credentials"])
    end

    it "should support delivering" do
      GitStoryid.any_instance.stubs(:readline).returns('1')
      run('-d')
      commands.should include(["git", "commit", "-m", "[Delivers #44647731] Feature: Strip Default paypal credentials"])
    end
  end

  it "should quit if no stories specified" do
    GitStoryid.any_instance.stubs(:readline).returns('')
    should_quit_with('Cancelling.') do
      run
    end
  end


  end


end
