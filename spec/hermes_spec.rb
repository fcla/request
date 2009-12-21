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

    LibXML::XML.default_keep_blanks = false
  end

   it "should return 401 if http authorization missing on request submission" do
    ieid = rand(1000)

    uri = "/requests/#{ieid}/disseminate"

    post uri
    last_response.status.should == 401
  end

  it "should return 401 if http authorization missing on request query" do
    ieid = rand(1000)

    uri = "/requests/#{ieid}/disseminate"

    get uri
    last_response.status.should == 401
  end

  it "should return 401 if http authorization missing on request deletion" do
    ieid = rand(1000)

    uri = "/requests/#{ieid}/disseminate"

    delete uri
    last_response.status.should == 401
  end

  it "should return 401 if http authorization missing on request approval" do
    ieid = rand(1000)

    uri = "/requests/#{ieid}/withdraw/approve"

    post uri
    last_response.status.should == 401
  end

  it "should return 401 if http authorization missing on query on ieid" do
    ieid = rand(1000)

    uri = "/requests/#{ieid}"

    get uri
    last_response.status.should == 401
  end

  it "should return 401 if http authorization missing on query by account name" do
    ieid = rand(1000)

    uri = "/requests_by_account/FDA"

    get uri
    last_response.status.should == 401
  end

  it "should return 401 if http authorization missing on multiple request submission" do
    uri = "/requests_by_xml"

    post uri
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

  it "should return 403 on unauthorized withdraw request deletion from valid user" do
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

  ###### Approval Requests
  
  it "should return 200 in response to a valid withdraw authorization request" do
    ieid = rand(1000)
    user = add_privileged_user
    op = add_op_user

    uri = "/requests/#{ieid}/withdraw"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    uri = "/requests/#{ieid}/withdraw/approve"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    last_response.status.should == 200
  end

  it "should set package request is_authorized state to true after a valid authorization request on it" do
    ieid = rand(1000)
    user = add_privileged_user
    op = add_op_user

    uri = "/requests/#{ieid}/withdraw"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    uri = "/requests/#{ieid}/withdraw/approve"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    uri = "/requests/#{ieid}/withdraw"

    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["request_type"].should == "withdraw"
    response_doc.root["ieid"].should == ieid.to_s
    response_doc.root["authorized"].should == "true"
  end

  it "should return 403 in response to a withdraw authorization request made by a non-operator" do
    ieid = rand(1000)
    user = add_privileged_user
    op = add_op_user

    uri = "/requests/#{ieid}/withdraw"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    uri = "/requests/#{ieid}/withdraw/approve"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 403
  end

  it "should return 403 in response to a withdraw authorization request made by the same user that requested the withdrawal" do
    ieid = rand(1000)
    op = add_op_user

    uri = "/requests/#{ieid}/withdraw"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    uri = "/requests/#{ieid}/withdraw/approve"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    last_response.status.should == 403
  end

  it "should return 404 in response to a withdrawal authorization request to an ieid with no pending withdrawal package request" do
    ieid = rand(1000)
    op = add_op_user

    uri = "/requests/#{ieid}/withdraw/approve"

    post uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    last_response.status.should == 404
  end

  ########## Query on IEID resource

  it "should return 200 OK in response to get on ieid resource" do
    ieid = rand(1000)
    op = add_op_user

    uri = "/requests/#{ieid}"

    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    last_response.status.should == 200
  end

  it "should return an XML document with all requests for a given ieid in response to GET on ieid resource" do
    ieid = rand(1000)
    op = add_op_user

    uri_disseminate = "/requests/#{ieid}/disseminate"
    uri_withdraw = "/requests/#{ieid}/withdraw"
    uri_peek = "/requests/#{ieid}/peek"

    post uri_disseminate, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    post uri_withdraw, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    post uri_peek, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    uri_ieid_query = "/requests/#{ieid}"

    get uri_ieid_query, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["ieid"].should == ieid.to_s

    children = response_doc.root.children
    children.length.should == 3

    children[0]["request_id"].should == "1"
    children[0]["request_type"].should == "disseminate"
    children[0]["requesting_user"].should == op.username
    children[0]["authorized"].should == "true"
    children[0]["ieid"].should == ieid.to_s

    children[1]["request_id"].should == "2"
    children[1]["request_type"].should == "withdraw"
    children[1]["requesting_user"].should == op.username
    children[1]["authorized"].should == "false"
    children[1]["ieid"].should == ieid.to_s

    children[2]["request_id"].should == "3"
    children[2]["request_type"].should == "peek"
    children[2]["requesting_user"].should == op.username
    children[2]["authorized"].should == "true"
    children[2]["ieid"].should == ieid.to_s
  end

  it "should return an XML document with all requests for a given ieid in response to get on ieid resource (even if there are no pending package requests)" do
    ieid = rand(1000)
    op = add_op_user

    uri_ieid_query = "/requests/#{ieid}"

    get uri_ieid_query, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["ieid"].should == ieid.to_s
  end

  ###### Query by account
  
  it "should return 200 OK in response to GET on requests_by_account resource" do
    op = add_op_user

    uri = "/requests_by_account/FDA"

    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    last_response.status.should == 200
  end

  it "should return an XML document with all the requests for a given account in response to get on query by account resource" do
    op = add_op_user

    ieid1 = rand(1000)
    ieid2 = rand(1000)
    ieid3 = rand(1000)

    uri1 = "/requests/#{ieid1}/disseminate"
    uri2 = "/requests/#{ieid2}/disseminate"
    uri3 = "/requests/#{ieid3}/disseminate"
    uri4 = "/requests/#{ieid1}/withdraw"
    uri5 = "/requests/#{ieid1}/peek"

    post uri1, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    post uri2, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    post uri3, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    post uri4, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    post uri5, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    uri = "/requests_by_account/FDA"

    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    # parse the XML document returned from the request service, testing the nodes for 
    # expected stucture, attributes, and values

    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["account"].should == "FDA"

    ieid_children = response_doc.root.children

    ieid_children.each do |ieid_child|
      req_children = ieid_child.children

      if req_children.length == 1
        req = req_children.shift

        ([ieid2, ieid3].include? req["ieid"].to_i).should == true
        req["request_type"].should == "disseminate"
      elsif req_children.length == 3
        while req = req_children.shift
          ieid1.to_s.should == req["ieid"]
          (["disseminate", "withdraw", "peek"].include? req["request_type"]).should == true
        end
      else
        raise StandardError, "Expecting nodes with 1 or 3 children"
      end
    end
  end

  it "should return 403 in response to GET on query by account resource made by unauthorized user" do
    user = add_non_privileged_user "FOO"

    uri = "/requests_by_account/FDA"

    get uri, {}, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    last_response.status.should == 403
  end

  # post multiple requests with xml document
  
  it "should return 201 CREATED in response to post to requests_by_xml resource, and create a new resource for each ieid specified" do
    ieid1 = rand(1000)
    ieid2 = rand(1000)
    ieid3 = rand(1000)

    op = add_op_user

    doc =<<-XML_UPLOAD
      <package_request_submission>
        <requests type="disseminate">
          <ieid_list>
            <ieid>#{ieid1}</ieid>
            <ieid>#{ieid2}</ieid>
            <ieid>#{ieid3}</ieid>
          </ieid_list>
        </requests>
      </package_request_submission>
    XML_UPLOAD

    uri = "/requests_by_xml"

    post uri, doc, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    last_response.status.should == 200

    uri1 = "/requests/#{ieid1}/disseminate"
    uri2 = "/requests/#{ieid2}/disseminate"
    uri3 = "/requests/#{ieid3}/disseminate"

    get uri1, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    last_response.status.should == 200

    get uri2, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    last_response.status.should == 200

    get uri3, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    last_response.status.should == 200
  end

  it "should return XML document correctly reporting resources created in response to POST to requests_by_xml resource" do
    ieid1 = rand(1000)
    ieid2 = rand(1000)
    ieid3 = rand(1000)

    op = add_op_user

    doc =<<-XML_UPLOAD
      <package_request_submission>
        <requests type="disseminate">
          <ieid_list>
            <ieid>#{ieid1}</ieid>
            <ieid>#{ieid2}</ieid>
            <ieid>#{ieid3}</ieid>
          </ieid_list>
        </requests>
      </package_request_submission>
    XML_UPLOAD

    uri = "/requests_by_xml"

    post uri, doc, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    doc = LibXML::XML::Document.string last_response.body

    doc.root["request_type"].should == "disseminate"

    children = doc.root.children
    children.length.should == 3

    children.each do |child|
      ([ieid1, ieid2, ieid3].include? child["ieid"].to_i).should == true
      child["outcome"].should == "created"
    end
  end

  it "should return XML document correctly reporting resources not created in response to POST to requests_by_xml resource (already exists)" do
    ieid1 = rand(1000)
    ieid2 = rand(1000)
    ieid3 = rand(1000)

    op = add_op_user

    uri1 = "/requests/#{ieid1}/disseminate"
    uri2 = "/requests/#{ieid2}/disseminate"
    uri3 = "/requests/#{ieid3}/disseminate"

    post uri1, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    post uri2, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}
    post uri3, {}, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    doc =<<-XML_UPLOAD
      <package_request_submission>
        <requests type="disseminate">
          <ieid_list>
            <ieid>#{ieid1}</ieid>
            <ieid>#{ieid2}</ieid>
            <ieid>#{ieid3}</ieid>
          </ieid_list>
        </requests>
      </package_request_submission>
    XML_UPLOAD

    uri = "/requests_by_xml"

    post uri, doc, {'HTTP_AUTHORIZATION' => encode_credentials(op.username, op.password)}

    doc = LibXML::XML::Document.string last_response.body

    doc.root["request_type"].should == "disseminate"

    children = doc.root.children
    children.length.should == 3

    children.each do |child|
      ([ieid1, ieid2, ieid3].include? child["ieid"].to_i).should == true
      child["outcome"].should == "not_created"
      child["error"].should == "already_exists"
    end
  end

  it "should return XML document correctly reporting resources not created in response to POST to requests_by_xml resource (not authorized)" do
    ieid1 = rand(1000)
    ieid2 = rand(1000)
    ieid3 = rand(1000)

    user = add_non_privileged_user

    doc =<<-XML_UPLOAD
      <package_request_submission>
        <requests type="disseminate">
          <ieid_list>
            <ieid>#{ieid1}</ieid>
            <ieid>#{ieid2}</ieid>
            <ieid>#{ieid3}</ieid>
          </ieid_list>
        </requests>
      </package_request_submission>
    XML_UPLOAD

    uri = "/requests_by_xml"

    post uri, doc, {'HTTP_AUTHORIZATION' => encode_credentials(user.username, user.password)}

    doc = LibXML::XML::Document.string last_response.body

    doc.root["request_type"].should == "disseminate"

    children = doc.root.children
    children.length.should == 3

    children.each do |child|
      ([ieid1, ieid2, ieid3].include? child["ieid"].to_i).should == true
      child["outcome"].should == "not_created"
      child["error"].should == "not_authorized"
    end
  end

  # query by parameters

  def encode_credentials(username, password)
    "Basic " + Base64.encode64("#{username}:#{password}")
  end
end
