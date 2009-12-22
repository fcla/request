require 'dispatch'
require 'wip'

describe Dispatch do

  URI_PREFIX = "test:/"

  before(:each) do
    FileUtils.mkdir_p "/tmp/d2ws"
    ENV["DAITSS_WORKSPACE"] = "/tmp/d2ws"
  end

  it "should create a dissemination sub-wip" do
    ieid = rand(1000)
    now = Time.now.to_s

    path_to_wip = Dispatch.dispatch_disseminate ieid

    wip = Wip.new path_to_wip, URI_PREFIX
    wip.tags["dissemination_request"].should == now
  end
end
