require "readline"
require "optparse"
require "pivotal_tracker"
require "yaml"
require "open3"

class GitStoryid

  def self.run(*args)
    new(*args).run
  end

  def initialize(*arguments)
    @git_options = []
    parser = OptionParser.new do |opts|
      opts.banner = "Do git commit with information from pivotal story"
      opts.on("-m", "--message [MESSAGE]", "Add addional MESSAGE to comit") do |custom_message|
        @custom_message = custom_message
      end
      opts.on("-f", "--finish", "Specify that this commit finishes a story or fixes a bug") do 
        @finish_stories = true
      end
    end
    parser.parse!(arguments)

    unless arguments.empty?
      @stories = arguments.map do |argument|
        Configuration.project.stories.find(argument) 
      end
    end
  end

  def all_stories
    @all_stories ||= Configuration.project.stories.all( 
      :owner => Configuration.me,
      :state => %w(started finished delivered),
      :limit => 30
    )
  end

  def readline_stories_if_not_present
    if !@stories || @stories.empty?
      quit_if_no_stories
      output stories_menu
      @stories = readline_story_ids.map do |index|
        if index > 1_000_000
          # Consider it a direct story id
          Configuration.project.stories.find(index)
        else
          all_stories[index - 1] || (quit("Story index #{index} not found."))
        end
      end
    end
  end

  def output(message)
    puts message
  end

  def quit_if_no_stories
    if all_stories.empty?
      quit "No stories started and owned by you."
    end
  end

  def stories_menu
    result = ""
    all_stories.each_with_index do |story, index|
      result << "[#{index + 1}] #{story.name}\n"
    end
    result << "\n"
    result
  end

  def readline_story_ids
    ids = readline.split(/\s*,\s*/).reject do |string|
      string.empty?
    end
    quit("Cancelling.") if ids.empty?
    ids.map {|id| id.to_i }
  end

  def readline
    Readline.readline("Indexes(csv): ", true)
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
    message = "[#{message}]".rjust(12)
    message += ' '
    if @custom_message && !@custom_message.empty?
      message += @custom_message.to_s + "\n\n"
    end
    message += @stories.map do |story|
      "#{story.story_type.capitalize}: " + story.name.strip
    end.join("\n\n")
    message
  end

  def finish_story_prefix(story)
    return "" unless @finish_stories
    story.story_type == "bug" ? "Fixes " : "Finishes "
  end

  def execute(*args)
    Open3.popen3(*args) {|i, o| return o.read }
  end

  def ensure_changes_stashed!
    if execute("git", "diff", "--staged").empty?
      quit "No changes staged to commit."
    end
  end


  module Configuration
    class << self

    def config=(config)
      @config = config
    end

    def read
      return if @loaded
      load_config
      ensure_full_config
      setup_api_client
      @loaded = true
    end

    def load_config
      @config ||= {}
      @config.merge!(load_config_from(global_config_path))
      @project_config = load_config_from(project_config_path)
      @config.merge!(@project_config)
    end

    def setup_api_client
      PivotalTracker::Client.token = @config['api_token']
      PivotalTracker::Client.use_ssl = @config['use_ssl'] ? @config['use_ssl'] : false
    end

    def ensure_full_config
      changed = false
      {
        "api_token" => "Api token (https://www.pivotaltracker.com/profile)",
        "use_ssl" => "Use SSL (y/n)",
        "me" => "Your pivotal initials (e.g. BG)",
        "project_id" => "Project ID"
      }.each do |key, label|
        if @config[key].nil?
          changed = true
          value = Readline.readline("#{label}: ", true) 
          @project_config[key]  = format_config_value(value)
        end
      end
      if changed
        File.open("./.pivotalrc", "w") do |file|
          file.write YAML.dump(@project_config)
        end
        @config.merge!(@project_config)
        #output "Writing config to .pivotalrc"
      end
    end

    def format_config_value(value)
      case value
      when "y"
        true
      when "n"
        false
      else
        value
      end
    end

    def load_config_from(path)
      return {} unless path
      file = File.join path,'.pivotalrc'
      if File.exists?(file)
        YAML.load(File.read(file)) || {}
      else 
        {}
      end
    end

    def project
      read
      @project ||= PivotalTracker::Project.find(@config['project_id'])
    end

    def me
      read
      @me ||= @config['me']
    end

    def global_config_path
      @global_config_path ||= File.expand_path('~')
    end

    def project_config_path
      @project_config_path ||= find_project_config
    end


    private

    def find_project_config
      dirs = File.split(Dir.pwd)
      until dirs.empty? || File.exists?(File.join(dirs, '.pivotalrc'))
        dirs.pop
      end
      if dirs.empty? || File.join(dirs, '.pivotalrc')==global_config_path
        nil
      else
        File.join(dirs)
      end
    end
    end
  end

  class Error < StandardError
  end
end
