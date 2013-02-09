require "spec_helper"
require "fileutils"

describe GitStoryid do

  before(:each) do
    FileUtils.rm_rf("spec/repo")
    FileUtils.mkdir_p("spec/repo")
    FileUtils.cd("spec/repo")
    `git init`
  end


end
