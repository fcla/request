#!/usr/bin/env ruby

require 'db/request'
require 'dispatch'
require 'daitss/config'
require 'db/operations_events'
require 'db/sip'

WORKSPACE = ENV["WORKSPACE"]

Daitss::CONFIG.load ENV['CONFIG']
DataMapper.setup :default, Daitss::CONFIG['database-url']

#for any request ieid for which there is no wip in the workspace, dispatch a "sub-wip" for that request

def create_op_agent
  existing = Program.first(:identifier => File.basename(__FILE__))
  return existing if existing

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

  return p
end

def insert_op_event agent, sip, request_id
  e = OperationsEvent.new
  e.attributes = { :timestamp => Time.now,
                   :event_name => "Request Released To Workspace",
                   :notes => "request_id: #{request_id}" }

  e.operations_agent = agent
  e.submitted_sip = sip

  e.save!
end

agent = create_op_agent

enqueued_and_authorized = Request.all(:is_authorized => true, :status => :enqueued, :order => [ :timestamp.asc ])

enqueued_and_authorized.each do |request|
  if Dispatch.wip_exists? request.submitted_sip.ieid
    next
  else
    Dispatch.dispatch_request request.submitted_sip.ieid, request.request_type 
    request.status = :released_to_workspace
    request.save!
  end

  insert_op_event agent, request.submitted_sip, request.id
end

