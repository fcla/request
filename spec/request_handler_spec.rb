require 'request_handler'
require 'helper'

describe RequestHandler do

  before(:each) do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/request.db")
    DataMapper.auto_migrate!

    a = add_account
    b = add_account "UF", "UF"

    @project = add_project a

    add_operator a
    add_operator a, "operator_2", "operator"
    add_operator b, "op_diff_act", "op_diff_act"

    add_contact a
    add_contact a, [:submit], "foobar", "foobar"
    add_contact b, [:submit, :disseminate, :withdraw, :peek], "contact_diff_act", "contact_diff_act"
  end

  it "should enqueue a new disseminate request requested by an operator" do
    ieid = rand(1000)
    add_intentity ieid, @project

    now = Time.now

    id = RequestHandler.enqueue_request "operator", :disseminate, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.intentity.id.should == ieid.to_s
    just_added.timestamp.to_time.should be_close(now, 1.0)
    just_added.is_authorized.should == true
    just_added.status.should == :enqueued
    just_added.request_type.should == :disseminate
    just_added.operations_agent.identifier.should == "operator"
    just_added.account.should == just_added.operations_agent.account

    pt_event = OperationsEvent.first(:ieid => ieid, :event_name => "Request Submission")

    pt_event.should_not be_nil
    pt_event.timestamp.to_time.should be_close(now, 1.0)
    pt_event.operations_agent.identifier.should == "operator"
    pt_event.notes.should == "request_type: disseminate, request_id: #{id}"
  end

  it "should enqueue a new withdraw request requested by an operator" do
    ieid = rand(1000)
    add_intentity ieid, @project

    now = Time.now

    id = RequestHandler.enqueue_request "operator", :withdraw, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.intentity.id.should == ieid.to_s
    just_added.timestamp.to_time.should be_close(now, 1.0)
    just_added.is_authorized.should == false
    just_added.status.should == :enqueued
    just_added.request_type.should == :withdraw
    just_added.operations_agent.identifier.should == "operator"
    just_added.account.should == just_added.operations_agent.account

    pt_event = OperationsEvent.first(:ieid => ieid, :event_name => "Request Submission")

    pt_event.should_not be_nil
    pt_event.timestamp.to_time.should be_close(now, 1.0)
    pt_event.operations_agent.identifier.should == "operator"
    pt_event.notes.should == "request_type: withdraw, request_id: #{id}"
  end

  it "should enqueue a new peek request requested by an operator" do
    ieid = rand(1000)
    add_intentity ieid, @project

    now = Time.now

    id = RequestHandler.enqueue_request "operator", :peek, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.intentity.id.should == ieid.to_s
    just_added.timestamp.to_time.should be_close(now, 1.0)
    just_added.is_authorized.should == true
    just_added.status.should == :enqueued
    just_added.request_type.should == :peek
    just_added.operations_agent.identifier.should == "operator"
    just_added.account.should == just_added.operations_agent.account

    pt_event = OperationsEvent.first(:ieid => ieid, :event_name => "Request Submission")

    pt_event.should_not be_nil
    pt_event.timestamp.to_time.should be_close(now, 1.0)
    pt_event.operations_agent.identifier.should == "operator"
    pt_event.notes.should == "request_type: peek, request_id: #{id}"
  end

  it "should raise error if attempting to enqueue unknown request type" do
    ieid = rand(1000)
    add_intentity ieid, @project

    lambda { id = RequestHandler.enqueue_request "operator", :foo, ieid }.should raise_error(InvalidRequestType)
  end

  it "should enqueue a new peek request requested by a privileged user" do
    ieid = rand(1000)
    add_intentity ieid, @project

    now = Time.now

    id = RequestHandler.enqueue_request "contact", :peek, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.intentity.id.should == ieid.to_s
    just_added.timestamp.to_time.should be_close(now, 1.0)
    just_added.is_authorized.should == true
    just_added.status.should == :enqueued
    just_added.request_type.should == :peek
    just_added.operations_agent.identifier.should == "contact"
    just_added.account.should == just_added.operations_agent.account

    pt_event = OperationsEvent.first(:ieid => ieid, :event_name => "Request Submission")

    pt_event.should_not be_nil
    pt_event.timestamp.to_time.should be_close(now, 1.0)
    pt_event.operations_agent.identifier.should == "contact"
    pt_event.notes.should == "request_type: peek, request_id: #{id}"
  end

  it "should enqueue a new withdrawal request requested by a privileged user" do
    ieid = rand(1000)
    add_intentity ieid, @project

    now = Time.now

    id = RequestHandler.enqueue_request "contact", :withdraw, ieid

    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.intentity.id.should == ieid.to_s
    just_added.timestamp.to_time.should be_close(now, 1.0)
    just_added.is_authorized.should == false
    just_added.status.should == :enqueued
    just_added.request_type.should == :withdraw
    just_added.operations_agent.identifier.should == "contact"
    just_added.account.should == just_added.operations_agent.account

    pt_event = OperationsEvent.first(:ieid => ieid, :event_name => "Request Submission")

    pt_event.should_not be_nil
    pt_event.timestamp.to_time.should be_close(now, 1.0)
    pt_event.operations_agent.identifier.should == "contact"
    pt_event.notes.should == "request_type: withdraw, request_id: #{id}"
  end

  it "should enqueue a new peek request requested by a privileged user" do
    ieid = rand(1000)
    add_intentity ieid, @project

    now = Time.now

    id = RequestHandler.enqueue_request "contact", :peek, ieid

    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.intentity.id.should == ieid.to_s
    just_added.timestamp.to_time.should be_close(now, 1.0)
    just_added.is_authorized.should == true
    just_added.status.should == :enqueued
    just_added.request_type.should == :peek
    just_added.operations_agent.identifier.should == "contact"
    just_added.account.should == just_added.operations_agent.account

    pt_event = OperationsEvent.first(:ieid => ieid, :event_name => "Request Submission")

    pt_event.should_not be_nil
    pt_event.timestamp.to_time.should be_close(now, 1.0)
    pt_event.operations_agent.identifier.should == "contact"
    pt_event.notes.should == "request_type: peek, request_id: #{id}"
  end

  it "should not enqueue a new disseminate request requested by a non-privileged user" do
    ieid = rand(1000)
    add_intentity ieid, @project

    lambda { RequestHandler.enqueue_request "foobar", :disseminate, ieid }.should raise_error(NotAuthorized)
  end

  it "should not enqueue a new withdraw request requested by a non-privileged user" do
    ieid = rand(1000)
    add_intentity ieid, @project

    lambda { RequestHandler.enqueue_request "foobar", :withdraw, ieid }.should raise_error(NotAuthorized)
  end

  it "should not enqueue a new peek request requested by a non-privileged user" do
    ieid = rand(1000)
    add_intentity ieid, @project

    lambda { RequestHandler.enqueue_request "foobar", :peek, ieid }.should raise_error(NotAuthorized)
  end

  it "should not enqueue a request if a request of that type is already enqueued for a given ieid" do
    ieid = rand(1000)
    add_intentity ieid, @project

    id = RequestHandler.enqueue_request "operator", :disseminate, ieid
    id2 = RequestHandler.enqueue_request "operator", :disseminate, ieid
    
    id2.should == nil
  end

  it "should allow an authorized operator to approve a withdrawal request, add add a package tracker record for the approval" do
    ieid = rand(1000)
    add_intentity ieid, @project

    request_id = RequestHandler.enqueue_request "operator", :withdraw, ieid

    now = Time.now
    history_id = RequestHandler.authorize_request(request_id, "operator_2")

    request_record = Request.get(request_id)

    request_record.is_authorized.should == true

    pt_event = OperationsEvent.first(:ieid => ieid, :event_name => "Request Approval")

    pt_event.should_not be_nil
    pt_event.timestamp.to_time.should be_close(now, 1.0)
    pt_event.operations_agent.identifier.should == "operator_2"
    pt_event.notes.should == "authorizing_agent: operator_2, request_id: #{request_id}"
  end

  it "should not allow an operator to approve own requests" do
    ieid = rand(1000)
    add_intentity ieid, @project

    request_id = RequestHandler.enqueue_request "operator", :withdraw, ieid

    lambda { history_id = RequestHandler.authorize_request(request_id, "operator") }.should raise_error(NotAuthorized)
  end

  it "should not allow a regular user to to approve own requests" do
    ieid = rand(1000)
    add_intentity ieid, @project

    request_id = RequestHandler.enqueue_request "contact", :withdraw, ieid

    lambda { history_id = RequestHandler.authorize_request(request_id, "contact") }.should raise_error(NotAuthorized)
  end

  it "should not allow a regular user to to approve another user's requests" do
    ieid = rand(1000)
    add_intentity ieid, @project

    request_id = RequestHandler.enqueue_request "contact", :withdraw, ieid

    lambda { history_id = RequestHandler.authorize_request(request_id, "foobar") }.should raise_error(NotAuthorized)
  end

  it "should allow an operator to query for requests by ieid and type" do
    ieid = rand(1000)
    add_intentity ieid, @project

    request_id = RequestHandler.enqueue_request "operator", :disseminate, ieid

    request = RequestHandler.query_request "operator", ieid, :disseminate

    request.should_not == nil
    request.id.should == request_id
  end

  it "should allow an authorized user to query for requests by ieid and type" do
    ieid = rand(1000)
    add_intentity ieid, @project

    request_id = RequestHandler.enqueue_request "contact", :disseminate, ieid

    request = RequestHandler.query_request "contact", ieid, :disseminate

    request.should_not == nil
    request.id.should == request_id
  end

  it "should allow an operator to delete a request by type and ieid" do
    ieid = rand(1000)
    add_intentity ieid, @project
    
    request_id = RequestHandler.enqueue_request "operator", :disseminate, ieid

    now = Time.now
    outcome = RequestHandler.delete_request "operator", ieid, :disseminate

    outcome.should == true
    Request.get(request_id).should == nil

    pt_event = OperationsEvent.first(:ieid => ieid, :event_name => "Request Deletion")

    pt_event.should_not be_nil
    pt_event.timestamp.to_time.should be_close(now, 1.0)
    pt_event.operations_agent.identifier.should == "operator"
    pt_event.notes.should == "request_id: #{request_id}"
  end

  it "should allow an authorized user to delete a request by type and ieid" do
    ieid = rand(1000)
    add_intentity ieid, @project
    
    request_id = RequestHandler.enqueue_request "contact", :disseminate, ieid

    now = Time.now
    outcome = RequestHandler.delete_request "contact", ieid, :disseminate

    outcome.should == true
    Request.get(request_id).should == nil

    pt_event = OperationsEvent.first(:ieid => ieid, :event_name => "Request Deletion")

    pt_event.should_not be_nil
    pt_event.timestamp.to_time.should be_close(now, 1.0)
    pt_event.operations_agent.identifier.should == "contact"
    pt_event.notes.should == "request_id: #{request_id}"
  end

  it "should allow operators to query all requests in a given account" do
    ieid1 = rand(1000)
    ieid2 = rand(1000)
    ieid3 = rand(1000)
    ieid4 = rand(1000)

    add_intentity ieid1, @project
    add_intentity ieid2, @project
    add_intentity ieid3, @project
    add_intentity ieid4, @project

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

    add_intentity ieid1, @project
    add_intentity ieid2, @project
    add_intentity ieid3, @project
    add_intentity ieid4, @project

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

  it "should raise error on a search for requests on an ieid that does not exist" do
    lambda { RequestHandler.query_ieid "operator", "1" }.should raise_error(NoSuchIntEntity)
  end

  it "should allow operators and contacts in account to query all requests in a given ieid" do
    ieid = rand(1000)
    add_intentity ieid, @project

    request_id1 = RequestHandler.enqueue_request "operator", :disseminate, ieid
    request_id2 = RequestHandler.enqueue_request "operator", :peek, ieid
    request_id3 = RequestHandler.enqueue_request "operator", :withdraw, ieid

    RequestHandler.dequeue_request request_id1, "operator"

    list1 = RequestHandler.query_ieid "operator", ieid
    list1.size.should == 3
    list1.each {|request| request.intentity.id.should == ieid.to_s }
    list1.each {|request| ([request_id1, request_id2, request_id3].include? request.id).should == true }

    list2 = RequestHandler.query_ieid "op_diff_act", ieid
    list2.size.should == 3
    list2.each {|request| request.intentity.id.should == ieid.to_s }
    list2.each {|request| ([request_id1, request_id2, request_id3].include? request.id).should == true }

    list3 = RequestHandler.query_ieid "contact", ieid
    list3.size.should == 3
    list3.each {|request| request.intentity.id.should == ieid.to_s }
    list3.each {|request| ([request_id1, request_id2, request_id3].include? request.id).should == true }
  end

  it "should not allow contacts in another account and invalid users to query all requests in a given ieid" do
    ieid = rand(1000)
    add_intentity ieid, @project

    request_id1 = RequestHandler.enqueue_request "operator", :disseminate, ieid
    request_id2 = RequestHandler.enqueue_request "operator", :peek, ieid
    request_id3 = RequestHandler.enqueue_request "operator", :withdraw, ieid

    RequestHandler.dequeue_request request_id1, "operator"

    lambda { RequestHandler.query_ieid "contact_diff_act", ieid }.should raise_error(NotAuthorized)
    lambda { RequestHandler.query_ieid "barbaz", ieid }.should raise_error(NotAuthorized)
  end

  it "should dequeue requests" do
    a = add_account
    p = add_program a

    ieid = rand(1000)
    add_intentity ieid, @project

    request_id = RequestHandler.enqueue_request "operator", :disseminate, ieid

    now = Time.now
    RequestHandler.dequeue_request request_id, p.identifier

    r = Request.get(request_id)

    r.status.should == :released_to_workspace

    pt_event = OperationsEvent.first(:ieid => ieid, :event_name => "Request Released to Workspace")

    pt_event.should_not be_nil
    pt_event.timestamp.to_time.should be_close(now, 1.0)
    pt_event.operations_agent.identifier.should == "bianchi:/Users/manny/code/git/request/poll-workspace"
    pt_event.notes.should == "request_id: #{request_id}"
  end

  it "shouldn't allow a non-existant user to queue a request" do
    ieid = rand(1000)
    add_intentity ieid, @project

    lambda { RequestHandler.enqueue_request "barbaz", :disseminate, ieid }.should raise_error(NotAuthorized)
  end

  it "shouldn't allow a user belonging to a different account from the package to queue a request" do
    ieid = rand(1000)
    add_intentity ieid, @project

    lambda { RequestHandler.enqueue_request "contact_diff_act", :disseminate, ieid }.should raise_error(NotAuthorized)
  end
  
  it "should allow an operator belonging to a different account from the package to queue a request" do
    ieid = rand(1000)
    add_intentity ieid, @project

    lambda { RequestHandler.enqueue_request "op_diff_act", :disseminate, ieid }.should_not raise_error(NotAuthorized)
  end

  it "should raise error if enqueing a request for an ieid that does not exist in intentity table" do
    ieid = rand(1000)
    lambda { RequestHandler.enqueue_request "operator", :disseminate, ieid }.should raise_error(NoSuchIntEntity)
  end

  it "should return nil if deleting a request for an ieid that does not exist in intentity table" do
    ieid = rand(1000)
    RequestHandler.delete_request("operator", ieid, :disseminate).should == nil
  end

  it "should return nil if querying a request for an ieid that does not exist in intentity table" do
    ieid = rand(1000)
    RequestHandler.query_request("operator", ieid, :disseminate).should == nil
  end
end
