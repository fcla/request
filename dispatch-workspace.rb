#!/usr/bin/env ruby

require 'db/request'
require 'dispatch'
require 'daitss/config'
require 'package_tracker'

WORKSPACE = ENV["WORKSPACE"]

Daitss::CONFIG.load ENV['CONFIG']
DataMapper.setup :default, Daitss::CONFIG['database-url']

#for any request ieid for which there is no wip in the workspace, dispatch a "sub-wip" for that request

def create_op_agent
  p = Program.new

  p.attributes = {
    :description => "request dispatch program",
    :active_start_date => Time.at(0),
    :active_end_date => Time.now + (86400 * 365),
    :identifier => File.basename(__FILE__)
  }

  fda_account = Account.first(:code => 'FDA', :name => 'FDA')
  raise "FDA account not present, please add it." unless fda_account
  p.account = fda_account

  k = AuthenticationKey.new
  k.attributes = { :auth_key => Digest::SHA1.hexdigest(__FILE__) }
  p.authentication_key = k

  p.save!
end

create_op_agent unless OperationsAgent.first(:identifier => File.basename(__FILE__))

enqueued_and_authorized = Request.all(:is_authorized => true, :status => :enqueued, :order => [ :timestamp.asc ])

enqueued_and_authorized.each do |request|
  if Dispatch.wip_exists? request.intentity.id
    next
  else
    Dispatch.dispatch_request request.intentity.id, request.request_type 
    request.status = :released_to_workspace
    request.save!
  end

  PackageTracker.insert_op_event File.basename(__FILE__), request.intentity.id, "Request Released To Workspace", "request_id: #{request.id}"
end

