require 'request_handler'
require 'helper'

describe RequestHandler do

  before(:each) do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/request.db")
    DataMapper.auto_migrate!

    a = add_account
    add_operator a
    add_operator a, "operator_2", "operator"
    add_contact a
    add_contact a, [:submit], "foobar", "foobar"
  end

  it "should enqueue a new disseminate request requested by an operator" do
    ieid = rand(1000)
    now = Time.now

    id = RequestHandler.enqueue_request "operator", :disseminate, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == true
    just_added.status.should == :enqueued
    just_added.request_type.should == :disseminate
    just_added.agent_identifier.should == "operator"
  end

  it "should enqueue a new withdraw request requested by an operator" do
    ieid = rand(1000)
    now = Time.now

    id = RequestHandler.enqueue_request "operator", :withdraw, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == false
    just_added.status.should == :enqueued
    just_added.request_type.should == :withdraw
    just_added.agent_identifier.should == "operator"
  end

  it "should enqueue a new peek request requested by an operator" do
    ieid = rand(1000)
    now = Time.now

    id = RequestHandler.enqueue_request "operator", :peek, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == true
    just_added.status.should == :enqueued
    just_added.request_type.should == :peek
    just_added.agent_identifier.should == "operator"
  end

  it "should raise error if attempting to enqueue unknown request type" do
    ieid = rand(1000)

    lambda { id = RequestHandler.enqueue_request "operator", :foo, ieid }.should raise_error(InvalidRequestType)
  end

  it "should enqueue a new disseminate request requested by a privileged user" do
    ieid = rand(1000)
    now = Time.now

    id = RequestHandler.enqueue_request "contact", :peek, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == true
    just_added.status.should == :enqueued
    just_added.request_type.should == :peek
    just_added.agent_identifier.should == "contact"
  end

  it "should enqueue a new withdrawal request requested by a privileged user" do
    ieid = rand(1000)
    now = Time.now

    id = RequestHandler.enqueue_request "contact", :withdraw, ieid

    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == false
    just_added.status.should == :enqueued
    just_added.request_type.should == :withdraw
    just_added.agent_identifier.should == "contact"
  end

  it "should enqueue a new peek request requested by a privileged user" do
    ieid = rand(1000)
    now = Time.now

    id = RequestHandler.enqueue_request "contact", :peek, ieid

    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == true
    just_added.status.should == :enqueued
    just_added.request_type.should == :peek
    just_added.agent_identifier.should == "contact"
  end

  it "should not enqueue a new disseminate request requested by a non-privileged user" do
    ieid = rand(1000)

    lambda { RequestHandler.enqueue_request "foobar", :disseminate, ieid }.should raise_error(NotAuthorized)
  end

  it "should not enqueue a new withdraw request requested by a non-privileged user" do
    ieid = rand(1000)

    lambda { RequestHandler.enqueue_request "foobar", :withdraw, ieid }.should raise_error(NotAuthorized)
  end

  it "should not enqueue a new peek request requested by a non-privileged user" do
    ieid = rand(1000)

    lambda { RequestHandler.enqueue_request "foobar", :peek, ieid }.should raise_error(NotAuthorized)
  end

  it "should not enqueue a request if a request of that type is already enqueued for a given ieid" do
    ieid = rand(1000)

    id = RequestHandler.enqueue_request "operator", :disseminate, ieid
    id2 = RequestHandler.enqueue_request "operator", :disseminate, ieid
    
    id2.should == nil
  end

  # TODO: query for request approval record in package tracker
  it "should allow an authorized operator to approve a withdrawal request, add add a package tracker record for the approval" do
    ieid = rand(1000)

    request_id = RequestHandler.enqueue_request "operator", :withdraw, ieid

    history_id = RequestHandler.authorize_request(request_id, "operator_2")

    request_record = Request.get(request_id)

    request_record.is_authorized.should == true

    # TODO: query goes here
  end

  it "should not allow an operator to approve own requests" do
    ieid = rand(1000)

    request_id = RequestHandler.enqueue_request "operator", :withdraw, ieid

    lambda { history_id = RequestHandler.authorize_request(request_id, "operator") }.should raise_error(NotAuthorized)
  end

  it "should not allow a regular user to to approve own requests" do
    ieid = rand(1000)

    request_id = RequestHandler.enqueue_request "contact", :withdraw, ieid

    lambda { history_id = RequestHandler.authorize_request(request_id, "contact") }.should raise_error(NotAuthorized)
  end

  it "should not allow a regular user to to approve another user's requests" do
    ieid = rand(1000)

    request_id = RequestHandler.enqueue_request "contact", :withdraw, ieid

    lambda { history_id = RequestHandler.authorize_request(request_id, "foobar") }.should raise_error(NotAuthorized)
  end

  it "should allow an operator to query for requests by ieid and type" do
    ieid = rand(1000)

    request_id = RequestHandler.enqueue_request "operator", :disseminate, ieid

    request = RequestHandler.query_request "operator", ieid, :disseminate

    request.should_not == nil
    request.id.should == request_id
  end

  it "should allow an authorized user to query for requests by ieid and type" do
    ieid = rand(1000)

    request_id = RequestHandler.enqueue_request "contact", :disseminate, ieid

    request = RequestHandler.query_request "contact", ieid, :disseminate

    request.should_not == nil
    request.id.should == request_id
  end

  it "should allow an operator to delete a request by type and ieid" do
    ieid = rand(1000)
    
    request_id = RequestHandler.enqueue_request "operator", :disseminate, ieid

    outcome = RequestHandler.delete_request "operator", ieid, :disseminate

    outcome.should == true
    Request.get(request_id).should == nil
  end

  it "should allow an authorized user to delete a request by type and ieid" do
    ieid = rand(1000)
    
    request_id = RequestHandler.enqueue_request "contact", :disseminate, ieid

    outcome = RequestHandler.delete_request "contact", ieid, :disseminate

    outcome.should == true
    Request.get(request_id).should == nil
  end

  it "should allow operators to query all requests in a given account" do
    ieid1 = rand(1000)
    ieid2 = rand(1000)
    ieid3 = rand(1000)
    ieid4 = rand(1000)

    request_id1 = RequestHandler.enqueue_request "operator", :disseminate, ieid1
    request_id2 = RequestHandler.enqueue_request "operator", :disseminate, ieid2
    request_id3 = RequestHandler.enqueue_request "operator", :disseminate, ieid3
    request_id4 = RequestHandler.enqueue_request "operator", :disseminate, ieid4

    set_of_request_ids = [request_id1, request_id2, request_id3, request_id4]

    requests = RequestHandler.query_account "operator", "FDA"

    requests.length.should == 4

    set_of_request_ids.include?(requests[0].id).should == true
    set_of_request_ids.include?(requests[1].id).should == true
    set_of_request_ids.include?(requests[2].id).should == true
    set_of_request_ids.include?(requests[3].id).should == true
  end

  it "should return nil on a search for requests on an account with no requests" do
    requests = RequestHandler.query_account "operator", "FDA"

    requests.length.should == 0
  end

  it "should allow privileged users to query all requests in a given account" do
    ieid1 = rand(1000)
    ieid2 = rand(1000)
    ieid3 = rand(1000)
    ieid4 = rand(1000)

    request_id1 = RequestHandler.enqueue_request "contact", :disseminate, ieid1
    request_id2 = RequestHandler.enqueue_request "contact", :disseminate, ieid2
    request_id3 = RequestHandler.enqueue_request "contact", :disseminate, ieid3
    request_id4 = RequestHandler.enqueue_request "contact", :disseminate, ieid4

    set_of_request_ids = [request_id1, request_id2, request_id3, request_id4]

    requests = RequestHandler.query_account "contact", "FDA"

    requests.length.should == 4

    set_of_request_ids.include?(requests[0].id).should == true
    set_of_request_ids.include?(requests[1].id).should == true
    set_of_request_ids.include?(requests[2].id).should == true
    set_of_request_ids.include?(requests[3].id).should == true
  end

  it "should allow operators to query all requests in a given ieid" do
    ieid = rand(1000)

    request_id1 = RequestHandler.enqueue_request "operator", :disseminate, ieid
    request_id2 = RequestHandler.enqueue_request "operator", :withdraw, ieid
    request_id3 = RequestHandler.enqueue_request "operator", :peek, ieid

    set_of_request_ids = [request_id1, request_id2, request_id3]

    requests = RequestHandler.query_ieid "operator", ieid

    requests.length.should == 3

    set_of_request_ids.include?(requests[0].id).should == true
    set_of_request_ids.include?(requests[1].id).should == true
    set_of_request_ids.include?(requests[2].id).should == true
  end

  it "should property return nil on a search for requests on an account with no requests" do
    requests = RequestHandler.query_ieid "operator", "1"

    requests.length.should == 0
  end

  it "should allow privileged users to query all requests in a given ieid" do
    pending "integration to service that knows what account a given ieid belongs to"
  end

  it "should not allow non-privileged users to query all requests in a given ieid" do
    pending "integration to service that knows what account a given ieid belongs to"
  end

  it "should dequeue requests" do
    ieid = rand(1000)

    request_id = RequestHandler.enqueue_request "operator", :disseminate, ieid

    RequestHandler.dequeue_request request_id

    r = Request.get(request_id)

    r.status.should == :released_to_workspace
  end

  it "shouldn't allow a bogus user to do anything" do
  end
end
