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

   it "should return 401 if authorization missing on request submission" do
    ieid = rand(1000)

    uri = "/requests/#{ieid}/disseminate"

    post uri
    last_response.status.should == 401
  end

  it "should return 401 if authorization missing on request query" do
    ieid = rand(1000)

    uri = "/requests/#{ieid}/disseminate"

    get uri
    last_response.status.should == 401
  end

  it "should return 401 if authorization missing on request deletion" do
    ieid = rand(1000)

    uri = "/requests/#{ieid}/disseminate"

    delete uri
    last_response.status.should == 401
  end

  ###### DISSEMINATE

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

  it "should return 403 on unauthorized dissemination request submission from valid user" do
    ieid = rand(1000)
    user = add_non_privileged_user

    uri = "/requests/#{ieid}/disseminate"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    last_response.status.should == 403
  end

  it "should return 403 on unauthorized dissemination request query from valid user" do
    ieid = rand(1000)
    user = add_non_privileged_user "FOO"
    op = add_op_user

    uri = "/requests/#{ieid}/disseminate"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 403
  end

  it "should return 200 on authorized dissemination request deletion from valid user" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/disseminate"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    delete uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 200
  end

  it "should delete exposed resource after successful dissemination request deletion" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/disseminate"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    delete uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 404
  end

  it "should return 404 on unauthorized dissemination request deletion from valid user" do
    ieid = rand(1000)
    user = add_non_privileged_user "FOO"
    op = add_op_user

    uri = "/requests/#{ieid}/disseminate"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    delete uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 403
  end

  ###### WITHDRAW

  it "should return 201 on authorized withdrawal request submission from valid user" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/withdraw"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    last_response.status.should == 201
  end

  it "should expose a request resource on authorized withdrawal request submission from valid user" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/withdraw"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    last_response.status.should == 200

    # TODO: add timestamp check
    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["request_type"].should == "withdraw"
    response_doc.root["ieid"].should == ieid.to_s
    response_doc.root["authorized"].should == "false"
    response_doc.root["requesting_user"].should == user.username
  end

  it "should return 403 on unauthorized withdrawal request submission from valid user" do
    ieid = rand(1000)
    user = add_non_privileged_user

    uri = "/requests/#{ieid}/withdraw"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    last_response.status.should == 403
  end

  it "should return 403 on unauthorized withdrawal request query from valid user" do
    ieid = rand(1000)
    user = add_non_privileged_user "FOO"
    op = add_op_user

    uri = "/requests/#{ieid}/withdraw"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 403
  end

  it "should return 200 on authorized withdrawal request deletion from valid user" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/withdraw"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    delete uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 200
  end

  it "should delete exposed resource after successful withdraw request deletion" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/withdraw"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    delete uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 404
  end

  it "should return 404 on unauthorized withdraw request deletion from valid user" do
    ieid = rand(1000)
    user = add_non_privileged_user "FOO"
    op = add_op_user

    uri = "/requests/#{ieid}/withdraw"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    delete uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 403
  end

  ###### PEEK

  it "should return 201 on authorized peek request submission from valid user" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/peek"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    last_response.status.should == 201
  end

  it "should expose a request resource on authorized peek request submission from valid user" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/peek"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    last_response.status.should == 200

    # TODO: add timestamp check
    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["request_type"].should == "peek"
    response_doc.root["ieid"].should == ieid.to_s
    response_doc.root["authorized"].should == "true"
    response_doc.root["requesting_user"].should == user.username
  end

  it "should return 403 on unauthorized peek request submission from valid user" do
    ieid = rand(1000)
    user = add_non_privileged_user

    uri = "/requests/#{ieid}/peek"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    last_response.status.should == 403
  end

  it "should return 403 on unauthorized peek request query from valid user" do
    ieid = rand(1000)
    user = add_non_privileged_user "FOO"
    op = add_op_user

    uri = "/requests/#{ieid}/peek"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 403
  end

  it "should return 200 on authorized peek request deletion from valid user" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/peek"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    delete uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 200
  end

  it "should delete exposed resource after successful peek request deletion" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/peek"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    delete uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 404
  end

  it "should return 404 on unauthorized peek request deletion from valid user" do
    ieid = rand(1000)
    user = add_non_privileged_user "FOO"
    op = add_op_user

    uri = "/requests/#{ieid}/peek"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    delete uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 403
  end

  it "should return 403 in response to any request that already exists" do
    ieid = rand(1000)
    user = add_op_user 

    uri = "/requests/#{ieid}/disseminate"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 403

    uri = "/requests/#{ieid}/withdraw"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 403

    uri = "/requests/#{ieid}/peek"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}
    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 403
  end


  def encode_credentials(username, password)
    "Basic " + Base64.encode64("#{username}:#{password}")
  end
end
