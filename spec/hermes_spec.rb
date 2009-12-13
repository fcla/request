require 'spec'
require 'rack/test'
require 'sinatra'
require 'hermes'
require 'helper'
require 'base64'
require 'libxml'

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
  
  it "should return 201 on authorized dissemination request submission from valid user" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/disseminate"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    last_response.status.should == 201
  end

  it "should expose a request resource on authorized disseimation request submission from valid user" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/disseminate"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    last_response.status.should == 200

    # TODO: add timestamp check
    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["request_type"].should == "disseminate"
    response_doc.root["ieid"].should == ieid.to_s
    response_doc.root["authorized"].should == "true"
    response_doc.root["requesting_user"].should == user.username
  end

  def encode_credentials(username, password)
    "Basic " + Base64.encode64("#{username}:#{password}")
  end
end
