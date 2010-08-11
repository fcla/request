require 'daitss/proc/wip'
require 'uri'
require 'daitss/config'
require 'daitss/proc/workspace'

class Dispatch

  Daitss::CONFIG.load_from_env
  WORKSPACE = Workspace.new(Daitss::CONFIG['workspace']).path 
  PREFIX_URI = "test:/"
  DISSEMINATE_DROP_PATH = "/tmp/disseminations/"
  
  # creates a dissemination "sub-wip" in the workspace 

  def self.dispatch_request ieid, type
    path = File.join(WORKSPACE, ieid.to_s)
    wip = Wip.new path, PREFIX_URI

    case type

    when :disseminate
      wip.tags["drop-path"] = DISSEMINATE_DROP_PATH
      wip.tags["dissemination-request"] = Time.now.to_s
    when :withdraw
      wip.tags["withdrawal-request"] = Time.now.to_s
    when :peek
      wip.tags["peek-request"] = Time.now.to_s
    else
      raise "Unknown request type: #{type}"
    end

    return path
  end

  def self.wip_exists? ieid
    File.exists? File.join(WORKSPACE, ieid.to_s)
  end
end
