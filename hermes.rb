#!/usr/bin/env ruby

require 'sinatra'
require 'user'
require 'request_handler'

require 'pp'

helpers do
  # returns true if http basic auth credentials have been included with request

  def credentials?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials
  end

  # returns array with http basic auth credentials passed in. returns nil if none provided

  def get_credentials
    return nil unless credentials? 

    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    return @auth.credentials
  end

  # returns a user object from a matching set of credentials found, nil otherwise

  def get_user
    user_credentials = get_credentials

    return nil if user_credentials == nil

    User.first(:username => user_credentials[0], :password => user_credentials[1])
  end

  # returns appropriate symbol based on type portion of uri
  def get_type uri_type_string
    return :disseminate if uri_type_string == "disseminate"
    return :withdraw if uri_type_string == "withdraw"
    return :peek if uri_type_string == "peek"
  end
end

# ***ROUTES***

# handle post requests for creation of single package request resource

post '/requests/:ieid/:type' do
  halt 401 unless credentials? 

  # get user credentials and use them to get a user object
  u = get_user

  # enqueue request
  begin
    enqueued = RequestHandler.enqueue_request u, get_type(params[:type]), params[:ieid] 
  rescue NotAuthorized
    halt 403
  end

  halt 403 unless enqueued

  halt 201 
end

# handle get requests on single package request resources

get '/requests/:ieid/:type' do
  halt 401 unless credentials? 

  u = get_user

  # look up request and user objects
  begin
    @request = RequestHandler.query_request u, params[:ieid], get_type(params[:type])

    if @request
      @user = @request.user
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

  u = get_user

  begin
    RequestHandler.delete_request u, params[:ieid], get_type(params[:type])
  rescue NotAuthorized
    halt 403
  end
end

# handle authorization requests on single package request resource

post '/requests/:ieid/:type/approve' do
  halt 401 unless credentials?

  u = get_user

  begin
    request = RequestHandler.query_request u, params[:ieid], get_type(params[:type])

    halt 404 if request == nil

    RequestHandler.authorize_request request.id, u
  rescue NotAuthorized
    halt 403
  end
end

# handle queries on entire IEIDs

get '/requests/:ieid' do
  halt 401 unless credentials?

  @ieid = params[:ieid]

  u = get_user

  begin
    @requests_by_ieid = RequestHandler.query_ieid u, @ieid
  rescue NotAuthorized
    halt 403
  end

  erb :ieid_requests
end
