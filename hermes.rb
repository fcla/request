#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
Bundler.setup

require 'sinatra'
require 'request_handler'
require 'libxml'
require 'db/operations_agent'
require 'daitss/config'

helpers do
  # returns true if http basic auth credentials have been included with request

  def credentials?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials
  end

  # returns array with http basic auth credentials passed in. returns nil if none provided

  def get_credentials
    return nil unless credentials?

    return @auth.credentials
  end

  # returns an operations_agent object from a matching set of credentials found, returns 403 otherwise

  def get_agent
    user_credentials = get_credentials

    return nil if user_credentials == nil

    Daitss::CONFIG.load_from_env
    DataMapper.setup :default, Daitss::CONFIG['database-url'] 

    agent = OperationsAgent.first(:identifier => user_credentials[0])

    if agent && agent.authentication_key.auth_key == Digest::SHA1.hexdigest(user_credentials[1])
      return agent
    else
      halt 403
    end
  end

  # returns appropriate symbol based on type portion of uri
  def get_type uri_type_string
    return :disseminate if uri_type_string == "disseminate"
    return :withdraw if uri_type_string == "withdraw"
    return :peek if uri_type_string == "peek"
  end

  # organizes an array of requests grouped by account such that all requests are grouped by ieid
  # returns a hash keyed by IEIDs, each bucket containing an array of request objects
  def group_by_ieid array_of_requests_by_account
    to_return = {}

    while req = array_of_requests_by_account.shift

      if to_return[req.submitted_sip.ieid]
        to_return[req.submitted_sip.ieid].push req
      else
        to_return[req.submitted_sip.ieid] = []
        to_return[req.submitted_sip.ieid].push req
      end
    end

    return to_return
  end

  # returns an body as LibXML Document object, raising exception if it cannot be parsed

  def get_body_as_doc body
    LibXML::XML.default_keep_blanks = false
    doc = LibXML::XML::Document.string body

    return doc
  end
end

# handle post requests for creation of single package request resource

post '/requests/:ieid/:type' do
  halt 401 unless credentials?

  # get agent credentials and use them to get a agent object
  agent = get_agent

  # enqueue request
  begin
    enqueued = RequestHandler.enqueue_request agent.identifier, get_type(params[:type]), params[:ieid]
  rescue NotAuthorized
    halt 403
  rescue NoSuchIntEntity
    halt 404
  end

  halt 403 unless enqueued

  halt 201
end

# handle get requests on single package request resources

get '/requests/:ieid/:type' do
  halt 401 unless credentials?

  agent = get_agent

  # look up request and agent objects
  begin
    @request = RequestHandler.query_request agent.identifier, params[:ieid], get_type(params[:type])

    if @request
    else
      halt 404
    end
  rescue NotAuthorized
    halt 403
  end

  erb :single_request
end

# handle delete requests on single package request resources

delete '/requests/:ieid/:type' do
  halt 401 unless credentials?

  agent = get_agent

  begin
    deleted = RequestHandler.delete_request agent.identifier, params[:ieid], get_type(params[:type])
    halt 404 if deleted == nil
  rescue NotAuthorized
    halt 403
  end
end

# handle authorization requests on single package request resource

post '/requests/:ieid/:type/approve' do
  halt 401 unless credentials?

  agent = get_agent

  begin
    request = RequestHandler.query_request agent.identifier, params[:ieid], get_type(params[:type])

    halt 404 if request == nil

    RequestHandler.authorize_request request.id, agent.identifier
  rescue NotAuthorized
    halt 403
  end
end

# handle queries on entire IEIDs

get '/requests/:ieid' do
  halt 401 unless credentials?

  @ieid = params[:ieid]

  agent = get_agent

  begin
    @requests_by_ieid = RequestHandler.query_ieid agent.identifier, @ieid
  rescue NotAuthorized
    halt 403
  rescue NoSuchIntEntity
    halt 404
  end

  erb :ieid_requests
end

# handles post requests for the creation of multiple request resource at once via XML

post '/requests_by_xml' do
  halt 401 unless credentials?

  agent = get_agent

  @created = []
  @already_exist = []
  @not_authorized = []

  # parse body as XML document. Returns 400 if body cannot be parsed
  begin
    doc = get_body_as_doc request.body.read
  rescue => e
    halt 400, "Unable to parse body as XML"
  end

  # determine the request type from body of request

  @type = get_type doc.root.first["type"]

  # iterate over all specified ieids, creating a request for each

  ieid_list_node = doc.root.first.first

  ieid_list_node.children.each do |ieid_node|
    ieid = ieid_node.first

    begin
      enqueued = RequestHandler.enqueue_request agent.identifier, @type, ieid.to_s
    rescue NotAuthorized
      @not_authorized.push ieid
    else
      if enqueued
        @created.push ieid
      else
        @already_exist.push ieid
      end
    end
  end

  erb :multiple_submission_response
end

# handles requests for queries based on parameters.
# TODO: this currently only works on and requires an "account" parameter. Needs to be modified to take
# any number/combination of parameters

get '/query_requests' do
  halt 401 unless credentials?

  halt 400 unless params["account"]

  agent = get_agent

  begin
    @account = params["account"]
    @requests_by_account = group_by_ieid RequestHandler.query_account agent.identifier, @account

    erb :account_requests
  rescue NotAuthorized
    halt 403
  end

end
