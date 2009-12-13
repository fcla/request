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

  # returns a user object if a matching set of credentials found, nil otherwise

  def get_user(username, password)
    User.first(:username => username, :password => password)
  end
end

# handle post requests to create new dissemination requests

post '/requests/:ieid/:type' do
  #puts ieid + " " + type
  #params[:ieid] + " " + params[:type]
  
  get_credentials[1]
  halt 201 
end
