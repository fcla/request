require 'helper'

require 'spec'
require 'rack/test'
require 'sinatra'
require 'hermes'
require 'helper'
require 'base64'
require 'libxml'


describe 'request service' do


  before(:each) do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/request.db")
    DataMapper.auto_migrate!

    a = add_account
    b = add_account "UF", "UF"

    add_contact a
    add_operator a
    add_contact a, [:submit], "foobar", "foobar"
    add_contact b, [:submit], "gator", "gator"
    add_operator b, "op_gator", "op_gator"

    @project = add_project a

    LibXML::XML.default_keep_blanks = false
  end

  def generate_ieid
    return rand(1000)
  end

  def authenticated_post uri, username, password, middle_param = {}
    post uri, middle_param, {'HTTP_AUTHORIZATION' => encode_credentials(username, password)}
  end

  def authenticated_get uri, username, password, middle_param = {}
    get uri, middle_param, {'HTTP_AUTHORIZATION' => encode_credentials(username, password)}
  end

  def authenticated_delete uri, username, password, middle_param = {}
    delete uri, middle_param, {'HTTP_AUTHORIZATION' => encode_credentials(username, password)}
  end

   it "should return 401 if http authorization missing on request submission" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}/disseminate"
    post uri

    last_response.status.should == 401
  end

  it "should return 401 if http authorization missing on request query" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/disseminate"
    get uri

    last_response.status.should == 401
  end

  it "should return 401 if http authorization missing on request deletion" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/disseminate"
    delete uri

    last_response.status.should == 401
  end

  it "should return 401 if http authorization missing on request approval" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw/approve"
    post uri

    last_response.status.should == 401
  end

  it "should return 401 if http authorization missing on query on ieid" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}"
    get uri

    last_response.status.should == 401
  end

  it "should return 401 if http authorization missing on query by account name" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/query_requests?account=FDA"
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
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/disseminate"
    authenticated_post uri, "operator", "operator"

    last_response.status.should == 201
  end

  it "should expose a request resource on authorized disseimation request submission from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    now = Time.now

    uri = "/requests/#{ieid}/disseminate"
    authenticated_post uri, "operator", "operator"
    authenticated_get uri, "operator", "operator"

    last_response.status.should == 200

    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["request_type"].should == "disseminate"
    response_doc.root["ieid"].should == ieid.to_s
    response_doc.root["authorized"].should == "true"
    response_doc.root["requesting_user"].should == "operator"
    Time.parse(response_doc.root["timestamp"]).should be_close(now, 1.0)
  end

  it "should return 403 on unauthorized dissemination request submission from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/disseminate"
    authenticated_post uri, "gator", "gator"

    last_response.status.should == 403
  end

  it "should return 403 on unauthorized dissemination request query from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/disseminate"
    authenticated_post uri, "operator", "operator"
    authenticated_get uri, "gator", "gator"

    last_response.status.should == 403
  end

  it "should return 200 on authorized dissemination request deletion from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/disseminate"
    authenticated_post uri, "operator", "operator"
    authenticated_delete uri, "operator", "operator"

    last_response.status.should == 200
  end

  it "should delete exposed resource after successful dissemination request deletion" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}/disseminate"
    authenticated_post uri, "operator", "operator"
    authenticated_delete uri, "operator", "operator"
    authenticated_get uri, "operator", "operator"

    last_response.status.should == 404
  end

  it "should return 403 on unauthorized dissemination request deletion from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/disseminate"
    authenticated_post uri, "operator", "operator"
    authenticated_delete uri, "gator", "gator"

    last_response.status.should == 403
  end

  it "should return 403 on dissemination request from contact from different account" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/disseminate"
    authenticated_post uri, "gator", "gator"

    last_response.status.should == 403
  end

  it "should return 201 on dissemination request from operator from different account" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/disseminate"
    authenticated_post uri, "op_gator", "op_gator"

    last_response.status.should == 201
  end

  it "should return 404 on request to enqueue an event for a ieid that does not exist" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}/disseminate"
    authenticated_post uri, "operator", "operator"

    last_response.status.should == 404
  end

  it "should return 404 on request to delete an event for a ieid that does not exist" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}/disseminate"
    authenticated_delete uri, "operator", "operator"

    last_response.status.should == 404
  end

  it "should return 404 on request to query an event for a ieid that does not exist" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}/disseminate"
    authenticated_get uri, "operator", "operator"

    last_response.status.should == 404
  end

  ###### WITHDRAW

  it "should return 201 on authorized withdrawal request submission from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "operator", "operator"

    last_response.status.should == 201
  end

  it "should expose a request resource on authorized withdrawal request submission from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    now = Time.now

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "operator", "operator"
    authenticated_get uri, "operator", "operator"

    last_response.status.should == 200

    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["request_type"].should == "withdraw"
    response_doc.root["ieid"].should == ieid.to_s
    response_doc.root["authorized"].should == "false"
    response_doc.root["requesting_user"].should == "operator"
    Time.parse(response_doc.root["timestamp"]).should be_close(now, 1.0)
  end

  it "should return 403 on unauthorized withdrawal request submission from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "foobar", "foobar"

    last_response.status.should == 403
  end

  it "should return 403 on unauthorized withdrawal request query from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "operator", "operator"
    authenticated_get uri, "gator", "gator"

    last_response.status.should == 403
  end

  it "should return 200 on authorized withdrawal request deletion from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "operator", "operator"
    authenticated_delete uri, "operator", "operator"

    last_response.status.should == 200
  end

  it "should delete exposed resource after successful withdraw request deletion" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "operator", "operator"
    authenticated_delete uri, "operator", "operator"
    authenticated_get uri, "operator", "operator"

    last_response.status.should == 404
  end

  it "should return 403 on unauthorized withdraw request deletion from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "operator", "operator"
    authenticated_delete uri, "gator", "gator"

    last_response.status.should == 403
  end

  it "should return 403 on withdraw request from contact from different account" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "gator", "gator"

    last_response.status.should == 403
  end

  it "should return 201 on withdraw request from operator from different account" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "op_gator", "op_gator"

    last_response.status.should == 201
  end

  it "should return 404 on request to enqueue an event for a ieid that does not exist" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "operator", "operator"

    last_response.status.should == 404
  end

  it "should return 404 on request to delete an event for a ieid that does not exist" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}/withdraw"
    authenticated_delete uri, "operator", "operator"

    last_response.status.should == 404
  end

  it "should return 404 on request to query an event for a ieid that does not exist" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}/withdraw"
    authenticated_get uri, "operator", "operator"

    last_response.status.should == 404
  end


  ###### PEEK

  it "should return 201 on authorized peek request submission from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/peek"
    authenticated_post uri, "operator", "operator"

    last_response.status.should == 201
  end

  it "should expose a request resource on authorized peek request submission from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project
    now = Time.now

    uri = "/requests/#{ieid}/peek"
    authenticated_post uri, "operator", "operator"
    authenticated_get uri, "operator", "operator"

    last_response.status.should == 200

    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["request_type"].should == "peek"
    response_doc.root["ieid"].should == ieid.to_s
    response_doc.root["authorized"].should == "true"
    response_doc.root["requesting_user"].should == "operator"
    Time.parse(response_doc.root["timestamp"]).should be_close(now, 1.0)
  end

  it "should return 403 on unauthorized peek request submission from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/peek"
    authenticated_post uri, "foobar", "foobar"

    last_response.status.should == 403
  end

  it "should return 403 on unauthorized peek request query from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/peek"
    authenticated_post uri, "operator", "operator"
    authenticated_get uri, "gator", "gator"

    last_response.status.should == 403
  end

  it "should return 200 on authorized peek request deletion from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/peek"
    authenticated_post uri, "operator", "operator"
    authenticated_delete uri, "operator", "operator"

    last_response.status.should == 200
  end

  it "should delete exposed resource after successful peek request deletion" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/peek"
    authenticated_post uri, "operator", "operator"
    authenticated_delete uri, "operator", "operator"
    authenticated_get uri, "operator", "operator"

    last_response.status.should == 404
  end

  it "should return 404 on unauthorized peek request deletion from valid user" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/peek"
    authenticated_post uri, "operator", "operator"
    authenticated_delete uri, "gator", "gator"

    last_response.status.should == 403
  end

  it "should return 403 in response to any request that already exists" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/disseminate"
    authenticated_post uri, "operator", "operator"
    authenticated_post uri, "operator", "operator"

    last_response.status.should == 403

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "operator", "operator"
    authenticated_post uri, "operator", "operator"

    last_response.status.should == 403

    uri = "/requests/#{ieid}/peek"
    authenticated_post uri, "operator", "operator"
    authenticated_post uri, "operator", "operator"

    last_response.status.should == 403
  end

  it "should return 403 on peek request from contact from different account" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/peek"
    authenticated_post uri, "gator", "gator"

    last_response.status.should == 403
  end

  it "should return 201 on peek request from operator from different account" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/peek"
    authenticated_post uri, "op_gator", "op_gator"

    last_response.status.should == 201
  end

  it "should return 404 on request to enqueue an event for a ieid that does not exist" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}/peek"
    authenticated_post uri, "operator", "operator"

    last_response.status.should == 404
  end

  it "should return 404 on request to delete an event for a ieid that does not exist" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}/peek"
    authenticated_delete uri, "operator", "operator"

    last_response.status.should == 404
  end

  it "should return 404 on request to query an event for a ieid that does not exist" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}/peek"
    authenticated_get uri, "operator", "operator"

    last_response.status.should == 404
  end

  ###### Approval Requests

  it "should return 200 in response to a valid withdraw authorization request" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "contact", "foobar"

    uri = "/requests/#{ieid}/withdraw/approve"
    authenticated_post uri, "operator", "operator"

    last_response.status.should == 200
  end

  it "should return 200 in response to a valid withdraw authorization request from an operator with a different account" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "contact", "foobar"

    uri = "/requests/#{ieid}/withdraw/approve"
    authenticated_post uri, "op_gator", "op_gator"

    last_response.status.should == 200
  end

  it "should set package request is_authorized state to true after a valid authorization request on it" do
    ieid = generate_ieid
    add_sip ieid, @project
    now = Time.now

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "contact", "foobar"

    uri = "/requests/#{ieid}/withdraw/approve"
    authenticated_post uri, "operator", "operator"

    uri = "/requests/#{ieid}/withdraw"
    authenticated_get uri, "contact", "foobar"

    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["request_type"].should == "withdraw"
    response_doc.root["ieid"].should == ieid.to_s
    response_doc.root["authorized"].should == "true"
    Time.parse(response_doc.root["timestamp"]).should be_close(now, 1.0)
  end

  it "should return 403 in response to a withdraw authorization request made by a non-operator" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "operator", "operator"

    uri = "/requests/#{ieid}/withdraw/approve"
    authenticated_post uri, "contact", "foobar"

    last_response.status.should == 403
  end

  it "should return 403 in response to a withdraw authorization request made by the same user that requested the withdrawal" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw"
    authenticated_post uri, "operator", "operator"

    uri = "/requests/#{ieid}/withdraw/approve"
    authenticated_post uri, "operator", "operator"

    last_response.status.should == 403
  end

  it "should return 404 in response to a withdrawal authorization request to an ieid with no pending withdrawal package request" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}/withdraw/approve"
    authenticated_post uri, "operator", "operator"

    last_response.status.should == 404
  end

  it "should return 404 on request to approve an event for a ieid that does not exist" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}/withdraw/approve"
    authenticated_get uri, "operator", "operator"

    last_response.status.should == 404
  end
  ########## Query on IEID resource

  it "should return 200 OK in response to get on ieid resource" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}"

    authenticated_get uri, "operator", "operator"
    last_response.status.should == 200

    authenticated_get uri, "op_gator", "op_gator"
    last_response.status.should == 200
  end

  it "should return an XML document with all requests for a given ieid in response to GET on ieid resource" do
    ieid = generate_ieid
    add_sip ieid, @project
    now = Time.now

    uri_disseminate = "/requests/#{ieid}/disseminate"
    uri_withdraw = "/requests/#{ieid}/withdraw"
    uri_peek = "/requests/#{ieid}/peek"

    authenticated_post uri_disseminate, "operator", "operator"
    authenticated_post uri_withdraw, "operator", "operator"
    authenticated_post uri_peek, "operator", "operator"

    uri_ieid_query = "/requests/#{ieid}"
    authenticated_get uri_ieid_query, "operator", "operator"

    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["ieid"].should == ieid.to_s

    children = response_doc.root.children
    children.length.should == 3

    children[0]["request_id"].should == "1"
    children[0]["request_type"].should == "disseminate"
    children[0]["requesting_user"].should == "operator"
    children[0]["authorized"].should == "true"
    children[0]["ieid"].should == ieid.to_s
    Time.parse(children[0]["timestamp"]).should be_close(now, 1.0)

    children[1]["request_id"].should == "2"
    children[1]["request_type"].should == "withdraw"
    children[1]["requesting_user"].should == "operator"
    children[1]["authorized"].should == "false"
    children[1]["ieid"].should == ieid.to_s
    Time.parse(children[1]["timestamp"]).should be_close(now, 1.0)

    children[2]["request_id"].should == "3"
    children[2]["request_type"].should == "peek"
    children[2]["requesting_user"].should == "operator"
    children[2]["authorized"].should == "true"
    children[2]["ieid"].should == ieid.to_s
    Time.parse(children[2]["timestamp"]).should be_close(now, 1.0)
  end

  it "should return an XML document with all requests for a given ieid in response to get on ieid resource (even if there are no pending package requests)" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri_ieid_query = "/requests/#{ieid}"
    authenticated_get uri_ieid_query, "operator", "operator"

    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["ieid"].should == ieid.to_s
  end

  it "should return 403 on request on ieid resource from contact on different account" do
    ieid = generate_ieid
    add_sip ieid, @project

    uri = "/requests/#{ieid}"
    authenticated_get uri, "gator", "gator"

    last_response.status.should == 403
  end

  it "should return 404 on request on ieid resource if ieid does not exist" do
    ieid = generate_ieid

    uri = "/requests/#{ieid}"
    authenticated_get uri, "operator", "operator"

    last_response.status.should == 404
  end

  ###### Query by account

  it "should return 200 OK in response to GET on requests_by_account resource" do

    uri = "/query_requests?account=FDA"
    authenticated_get uri, "operator", "operator"

    last_response.status.should == 200
  end

  it "should return an XML document with all the requests for a given account in response to get on query by account resource" do
    now = Time.now

    ieid1 = generate_ieid
    ieid2 = generate_ieid
    ieid3 = generate_ieid

    add_sip ieid1, @project
    add_sip ieid2, @project
    add_sip ieid3, @project

    uri1 = "/requests/#{ieid1}/disseminate"
    uri2 = "/requests/#{ieid2}/disseminate"
    uri3 = "/requests/#{ieid3}/disseminate"
    uri4 = "/requests/#{ieid1}/withdraw"
    uri5 = "/requests/#{ieid1}/peek"

    authenticated_post uri1, "operator", "operator"
    authenticated_post uri2, "operator", "operator"
    authenticated_post uri3, "operator", "operator"
    authenticated_post uri4, "operator", "operator"
    authenticated_post uri5, "operator", "operator"

    uri = "/query_requests?account=FDA"
    authenticated_get uri, "operator", "operator"

    # parse the XML document returned from the request service, testing the nodes for
    # expected stucture, attributes, and values
    # TODO: refactor

    response_doc = LibXML::XML::Document.string last_response.body

    response_doc.root["account"].should == "FDA"

    ieid_children = response_doc.root.children

    ieid_children.each do |ieid_child|
      req_children = ieid_child.children

      if req_children.length == 1
        req = req_children.shift

        ([ieid2, ieid3].include? req["ieid"].to_i).should == true
        req["request_type"].should == "disseminate"
        Time.parse(req["timestamp"]).should be_close(now, 1.0)
      elsif req_children.length == 3
        while req = req_children.shift
          ieid1.to_s.should == req["ieid"]
          (["disseminate", "withdraw", "peek"].include? req["request_type"]).should == true
          Time.parse(req["timestamp"]).should be_close(now, 1.0)
        end
      else
        raise StandardError, "Expecting nodes with 1 or 3 children"
      end
    end
  end

  it "should return 403 in response to GET on query by account resource made by contact from another account" do

    uri = "/query_requests?account=FDA"
    authenticated_get uri, "gator", "gator"

    last_response.status.should == 403
  end

  it "should return 200 in response to GET on query by account resource made by operator from another account" do

    uri = "/query_requests?account=FDA"
    authenticated_get uri, "op_gator", "op_gator"

    last_response.status.should == 200
  end

  it "should return 400 in response to GET on query by account if account is missing" do

    uri = "/query_requests"
    authenticated_get uri, "contact", "foobar"

    last_response.status.should == 400
  end

  # post multiple requests with xml document

  it "should return 201 CREATED in response to post to requests_by_xml resource, and create a new resource for each ieid specified" do
    ieid1 = generate_ieid
    ieid2 = generate_ieid
    ieid3 = generate_ieid

    add_sip ieid1, @project
    add_sip ieid2, @project
    add_sip ieid3, @project

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
    authenticated_post uri, "operator", "operator", doc

    last_response.status.should == 200

    uri1 = "/requests/#{ieid1}/disseminate"
    uri2 = "/requests/#{ieid2}/disseminate"
    uri3 = "/requests/#{ieid3}/disseminate"

    authenticated_get uri1, "operator", "operator"
    last_response.status.should == 200

    authenticated_get uri2, "operator", "operator"
    last_response.status.should == 200

    authenticated_get uri3, "operator", "operator"
    last_response.status.should == 200
  end

  it "should return XML document correctly reporting resources created in response to POST to requests_by_xml resource" do
    ieid1 = generate_ieid
    ieid2 = generate_ieid
    ieid3 = generate_ieid

    add_sip ieid1, @project
    add_sip ieid2, @project
    add_sip ieid3, @project

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
    authenticated_post uri, "operator", "operator", doc

    doc = LibXML::XML::Document.string last_response.body

    doc.root["request_type"].should == "disseminate"

    children = doc.root.children
    children.length.should == 3

    children.each do |child|
      ([ieid1, ieid2, ieid3].include? child["ieid"].to_i).should == true
      child["outcome"].should == "created"
    end
  end

  it "should return XML document correctly reporting resources created in response to POST to requests_by_xml resource by operator from another account" do
    ieid1 = generate_ieid
    ieid2 = generate_ieid
    ieid3 = generate_ieid

    add_sip ieid1, @project
    add_sip ieid2, @project
    add_sip ieid3, @project

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
    authenticated_post uri, "op_gator", "op_gator", doc

    doc = LibXML::XML::Document.string last_response.body

    doc.root["request_type"].should == "disseminate"

    children = doc.root.children
    children.length.should == 3

    children.each do |child|
      ([ieid1, ieid2, ieid3].include? child["ieid"].to_i).should == true
      child["outcome"].should == "created"
    end
  end

  it "should return XML document correctly reporting resources not created in response to POST to requests_by_xml resource (resources not created because they already exist)" do
    ieid1 = generate_ieid
    ieid2 = generate_ieid
    ieid3 = generate_ieid

    add_sip ieid1, @project
    add_sip ieid2, @project
    add_sip ieid3, @project

    uri1 = "/requests/#{ieid1}/disseminate"
    uri2 = "/requests/#{ieid2}/disseminate"
    uri3 = "/requests/#{ieid3}/disseminate"

    authenticated_post uri1, "operator", "operator"
    authenticated_post uri2, "operator", "operator"
    authenticated_post uri3, "operator", "operator"

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
    authenticated_post uri, "operator", "operator", doc

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
    ieid1 = generate_ieid
    ieid2 = generate_ieid
    ieid3 = generate_ieid

    add_sip ieid1, @project
    add_sip ieid2, @project
    add_sip ieid3, @project

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
    authenticated_post uri, "foobar", "foobar", doc

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

  it "should return XML document correctly reporting resources not created in response to POST to requests_by_xml resource (wrong account)" do
    ieid1 = generate_ieid
    ieid2 = generate_ieid
    ieid3 = generate_ieid

    add_sip ieid1, @project
    add_sip ieid2, @project
    add_sip ieid3, @project

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
    authenticated_post uri, "gator", "gator", doc

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

  it "should handle queries on ieids appropriatly" do
  end

  # query by parameters

  def encode_credentials(username, password)
    "Basic " + Base64.encode64("#{username}:#{password}")
  end
end
