require "readline"
require "optparse"
require "yaml"
require "open3"
require 'io/console'

class GitStoryid

  def self.run(*args)
    new(*args).run
  end

  def self.output(message)
    puts message
  end

  def output(message)
    self.class.output(message)
  end


  def initialize(*arguments)
    @tracker = Configuration.build
    @git_options = []
    parser = OptionParser.new do |opts|
      opts.banner = "Do git commit with information from pivotal story"
      opts.on("-m", "--message [MESSAGE]", "Add addional MESSAGE to comit") do |custom_message|
        @custom_message = custom_message
      end
      opts.on("-f", "--finish", "Specify that this commit finishes a story or fixes a bug") do
        @finish_stories = true
      end
      opts.on("-d", "--deliver", "Specify that this commit delivers a story or a bug") do
        @deliver_stories = true
      end
    end
    parser.parse!(arguments)

    unless arguments.empty?
      @stories = arguments.map do |argument|
        @tracker.find_story_by_id(argument)
      end
    end
  end

  def readline_stories_if_not_present
    if !@stories || @stories.empty?
      quit_if_no_stories
      output stories_menu
      @stories = readline_story_ids.map do |index|
        fetch_story(index) || quit("Story #{index} was not found.")
      end
    end
  rescue RefetchStories
    @tracker.reset
    @stories = nil
    readline_stories_if_not_present
  end

  def fetch_story(index)
    if (1..100).include?(index.to_i)
      @tracker.all_stories[index.to_i - 1]
    else
      # Consider it a direct story id
      @tracker.find_story_by_id(index)
    end
  end

  def quit_if_no_stories
    if @tracker.all_stories.empty?
      quit "No stories started and owned by you."
    end
  end

  def stories_menu
    result = ""
    @tracker.all_stories.each_with_index do |story, index|
      result << "[#{index + 1}] #{story.name}\n"
    end
    result << "\n"
    result
  end

  def readline_story_ids
    input = readline
    if input =~ /\A\s*re?f?r?e?s?h?\s*\z/
      raise RefetchStories
    end
    ids = input.split(/\s*,\s*/).reject do |string|
      string.empty?
    end
    if ids.empty?
      quit("Cancelling.")
    else
      ids
    end
  end

  def readline
    Readline.readline("Indexes: ", true)
  end

  def quit(message)
    output message
    exit 1
  end

  def run
    ensure_changes_stashed!
    readline_stories_if_not_present
    commit_changes
  end

  def commit_changes
    output execute("git", "commit", "-m", build_commit_message)
  end

  def build_commit_message
    message = @stories.map do |story|
      "#{finish_story_prefix(story)}##{story.id}"
    end.join(", ")
    message = "[#{message}] "
    if @custom_message && !@custom_message.empty?
      message += @custom_message.to_s + "\n\n"
    end
    message += @stories.map do |story|
      "#{story.type.capitalize}: " + story.name.strip
    end.join("\n\n")
    message
  end

  def finish_story_prefix(story)
    return "Delivers " if @deliver_stories
    return "" unless @finish_stories
    story.type == "bug" ? "Fixes " : "Finishes "
  end

  def execute(*args)
    Open3.popen3(*args) {|i, o| return o.read }
  end

  def ensure_changes_stashed!
    if execute("git", "diff", "--staged").empty?
      quit "No changes staged to commit."
    end
  end

  class Configuration

    def self.build
      load_config
      ensure_full_config
      TRACKER_CONFIG[engine][:class].new(@config)
    end

    class << self

      def load_config
        @config ||= load_config_from
      end

      def engine
        e = @config[:engine]
        e ? e.to_sym : nil
      end

      def ensure_full_config
        @config[:engine] = read_configuration_value("Engine (pivotal/jira)") unless engine
        tracker_config = TRACKER_CONFIG[engine]

        return if tracker_config && @config.keys.sort == (tracker_config[:options].keys + [:engine]).sort

        tracker_config[:options].each do |key, label|
          @config[key] = read_configuration_value(label, key == :password)
        end

        File.open(project_config_path, "w") do |file|
          file.write YAML.dump(@config)
        end
        output "Writing config to #{project_config_path}"
      end

      def read_configuration_value(label, hidden = false)
        label = "#{label}: "
        if hidden
          print label
          password = STDIN.noecho(&:gets).chomp
          puts ''
          password
        else
          Readline.readline(label, true)
        end
      end

      def load_config_from
        return {} unless project_config_path
        if File.exists?(project_config_path)
          YAML.load(File.read(project_config_path)) || {}
        else
          {}
        end
      end

      def project_config_path
        @project_config_path ||= find_project_config
      end
      def find_project_config
        dirs = File.split(Dir.pwd)
        until dirs.empty? || File.exists?(File.join(dirs, FILENAME))
          dirs.pop
        end
        unless dirs.empty?
          File.join(dirs, FILENAME)
        else
          File.join(Dir.pwd, FILENAME)
        end
      end
    end

    def initialize(config)
      @config = config
      setup_api_client
    end

    def all_stories
      @all_stories ||= fetch_all_stories.map do |story|
        serialize_issue(story)
      end
    end

    def reset
      @all_stories = nil
    end

    def self.output(message)
      GitStoryid.output(message)
    end


    FILENAME = %w(.git-storyid)

  end

  class SerializedIssue < Struct.new(:id, :type, :name)
  end
  class PivotalConfiguration < Configuration

    def setup_api_client
      require "tracker_api"
      @client ||= TrackerApi::Client.new(token: @config[:api_token])
    end

    def me
      @me ||= @config['me']
    end

    def fetch_all_stories
      project.stories(
        filter: "mywork:#{me} state:started,finished,delivered",
        # :owner => me,
        # :with_state => %w(started finished delivered),
        :limit => 30
      )
    end

    def find_story_by_id(id)
      serialize_issue(project.story(id))
    end

    def serialize_issue(issue)
      SerializedIssue.new(issue.id, issue.story_type, issue.name)
    end

    protected
    def project
      @project ||= @client.project(@config['project_id'])
    end

  end


  class JiraConfiguration < Configuration

    def initialize(config)
      super(config)
    end

    def setup_api_client
      require 'jira-ruby'
      @client ||= JIRA::Client.new(
        :username     => username,
        :password     => @config[:password],
        :site         => @config[:site],
        :context_path => '',
        :auth_type    => :basic,
      )
    end

    def client
      @client
    end

    def username
      @username ||= @config[:username]
    end

    def fetch_all_stories
      client.Issue.jql("assignee=#{username} and status not in (done) and project = #{@config[:project_id]}")
    end

    def find_story_by_id(key)
      if key.to_i.to_s == key.to_s # no project_id in key
        key = [@config[:project_id], key].join("-")
      end
      serialize_issue(client.Issue.find(key))
    rescue JIRA::HTTPError => e
      if e.code.to_i == 404
        nil
      else
        raise e
      end
    end

    def serialize_issue(issue)
      SerializedIssue.new(issue.key, issue.issuetype.name, issue.summary)
    end

  end

  class Error < StandardError
  end

  class RefetchStories < StandardError
  end

  TRACKER_CONFIG = {
    pivotal: {
      class: PivotalConfiguration,
      options: {
        :api_token => "Api token (https://www.pivotaltracker.com/profile)",
        :me => "Your pivotal initials (e.g. BG)",
        :project_id => "Project ID",
      },
    },
    jira: {
      class: JiraConfiguration,
      options: {
        :site         => 'Site URL',
        project_id: "Project ID",
        :username     => 'Username',
        :password     => 'Password',
      }
    }
  }


end
