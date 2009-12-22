require 'wip'
require 'uri'

class Dispatch

  WORKSPACE = ENV["DAITSS_WORKSPACE"]
  PREFIX_URI = "test:/"
  
  # creates a dissemination "sub-wip" in the workspace 

  def self.dispatch_disseminate ieid
    path = File.join(WORKSPACE, ieid.to_s)
    wip = Wip.new path, PREFIX_URI

    wip.tags["dissemination_request"] = Time.now.to_s

    return path
  end

  def self.dispatch_peek ieid
    path = File.join(WORKSPACE, ieid.to_s)
    wip = Wip.new path, PREFIX_URI

    wip.tags["peek_request"] = Time.now.to_s

    return path
  end

  def self.dispatch_withdraw ieid
    path = File.join(WORKSPACE, ieid.to_s)
    wip = Wip.new path, PREFIX_URI

    wip.tags["withdrawal_request"] = Time.now.to_s

    return path
  end

  def self.wip_exists? ieid
    File.exists? File.join(WORKSPACE, ieid.to_s)
  end
end
