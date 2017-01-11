
require "spec_helper"
require "fileutils"

describe GitStoryid do

  let(:commands) { []}

  def run(*args)
    GitStoryid.run(*args)
  end

  def should_quit_with(expected)
    actual = nil
    GitStoryid.send(:define_method, :quit) do |message|
      actual = message
    end
    yield
    actual.should_not be_nil
    actual.should == expected

  end


  describe "Pivotal" do

    before(:each) do

      GitStoryid::Configuration.stubs(:load_config_from).
        returns(
          "api_token" => "a2b4e",
          "use_ssl" => false,
          "me" => "BG",
          "project_id" => "1234"
      )
      commands = self.commands
      GitStoryid.send(:define_method, :execute) do |*args|
        commands << args
        ""
      end
      GitStoryid.any_instance.stubs(:ensure_changes_stashed!).returns(true)
      GitStoryid.any_instance.stubs(:output).returns(true)

      GitStoryid::Configuration.stubs(:project).returns(Hashie::Mash.new(
        :initial_velocity => 10,
        :labels => "bonobos,true&co,website",
        :id => 135657,
        :week_start_day => "Monday",
        :use_https => false,
        :iteration_length => 1,
        :account => "Allan Grant",
        :name => "Curebit Marketing",
        :stories => PivotalTracker::Story,
        :last_activity_at => DateTime.now,
        :velocity_scheme => "Average of 3 iterations",
        :current_iteration_number => 122,
        :current_velocity => 19,
        :point_scale => "0,1,2,3",
        :first_iteration_start_time => DateTime.now
      ))

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
  end
end
