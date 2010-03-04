require 'dispatch'
require 'wip'

describe Dispatch do

  URI_PREFIX = "test:/"

  before(:each) do
    FileUtils.mkdir_p "/tmp/d2ws"
    ENV["WORKSPACE"] = "/tmp/d2ws"
  end

  after(:each) do
    FileUtils.rm_rf "/tmp/d2ws"
  end

  it "should create a dissemination sub-wip" do
    ieid = rand(1000)
    now = Time.now.to_s

    path_to_wip = Dispatch.dispatch_request ieid, :disseminate

    wip = Wip.new path_to_wip
    wip.tags["dissemination-request"].should == now
  end

  it "should create a withdrawl sub-wip" do
    ieid = rand(1000)
    now = Time.now.to_s

    path_to_wip = Dispatch.dispatch_request ieid, :withdraw

    wip = Wip.new path_to_wip
    wip.tags["withdrawal-request"].should == now
  end

  it "should create a peek sub-wip" do
    ieid = rand(1000)
    now = Time.now.to_s

    path_to_wip = Dispatch.dispatch_request ieid, :peek

    wip = Wip.new path_to_wip
    wip.tags["peek-request"].should == now
  end

  it "should correctly tell when a wip for an ieid exists in the workspace" do
    ieid = rand(1000)

    path_to_wip = Dispatch.dispatch_request ieid, :disseminate

    Dispatch.wip_exists?(ieid).should == true
  end

  it "should correctly tell when a wip for an ieid does not exist in the workspace" do
    ieid = rand(1000)

    Dispatch.wip_exists?(ieid).should == false
  end
end
