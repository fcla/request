#!/usr/bin/env ruby

require 'db/request'
require 'dispatch'

WORKSPACE = ENV["WORKSPACE"]

#for any request ieid for which there is no wip in the workspace, dispatch a "sub-wip" for that request

enqueued_and_authorized = Request.all(:is_authorized => true, :status => :enqueued, :order => [ :timestamp.asc ])

enqueued_and_authorized.each do |request|
  if Dispatch.wip_exists? request.ieid
    next
  else
    Dispatch.dispatch_request request.ieid, request.request_type 
    request.status = :released_to_workspace
    request.save!
  end
end

