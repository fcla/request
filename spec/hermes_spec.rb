require 'spec'
require 'rack/test'
require 'sinatra'
require 'hermes'
require 'helper'
require 'base64'

require 'pp'

include Rack::Test::Methods

set :environment, :test


describe "Request Service (Hermes)" do

  def app
    Sinatra::Application
  end

  before(:each) do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/request.db")
    DataMapper.auto_migrate!
  end
  
  it "should return 201 on authorized dissemination request from valid user" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/disseminate"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    last_response.status.should == 201
  end

  def encode_credentials(username, password)
    "Basic " + Base64.encode64("#{username}:#{password}")
  end
end
