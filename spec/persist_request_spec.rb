require 'persist_request'
require 'pp'

describe PersistRequest do

  before(:each) do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/request.db")
    DataMapper.auto_migrate!
  end

  def add_op_user
    user = User.new

    user.attributes = {
      :username => "op",
      :password => "op",
      :account => "FDA",
      :is_operator => true,
      :can_disseminate => true,
      :can_withdraw => false,
      :can_peek => false
    }

    user.save

    return user
  end

  def add_privileged_user
    user = User.new

    user.attributes = {
      :username => "priv",
      :password => "priv",
      :account => "FDA",
      :is_operator => false,
      :can_disseminate => true,
      :can_withdraw => true,
      :can_peek => true
    }

    user.save

    return user
  end

  def add_non_privileged_user account = "FDA"
    user = User.new

    user.attributes = {
      :username => "nopriv",
      :password => "nopriv",
      :account => account,
      :is_operator => false,
      :can_disseminate => false,
      :can_withdraw => false,
      :can_peek => false
    }

    user.save

    return user
  end

  it "should enqueue a new disseminate request requested by an operator" do
    op = add_op_user
    ieid = rand(1000)
    now = Time.now

    id = PersistRequest.enqueue_request op, :disseminate, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == true
    just_added.status.should == :enqueued
    just_added.request_type.should == :disseminate
  end

  it "should enqueue a new withdraw request requested by an operator" do
    op = add_op_user
    ieid = rand(1000)
    now = Time.now

    id = PersistRequest.enqueue_request op, :withdraw, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == false
    just_added.status.should == :enqueued
    just_added.request_type.should == :withdraw
  end

  it "should enqueue a new peek request requested by an operator" do
    op = add_op_user
    ieid = rand(1000)
    now = Time.now

    id = PersistRequest.enqueue_request op, :peek, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == true
    just_added.status.should == :enqueued
    just_added.request_type.should == :peek
  end

  it "should raise error if attempting to enqueue unknown request type" do
    op = add_op_user
    ieid = rand(1000)

    lambda { id = PersistRequest.enqueue_request op, :foo, ieid }.should raise_error(InvalidRequestType)
  end

  it "should enqueue a new disseminate request requested by a privileged user" do
    priv_user = add_privileged_user
    ieid = rand(1000)
    now = Time.now

    id = PersistRequest.enqueue_request priv_user, :peek, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == true
    just_added.status.should == :enqueued
    just_added.request_type.should == :peek
  end

  it "should enqueue a new withdrawal request requested by a privileged user" do
    priv_user = add_privileged_user
    ieid = rand(1000)
    now = Time.now

    id = PersistRequest.enqueue_request priv_user, :withdraw, ieid

    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == false
    just_added.status.should == :enqueued
    just_added.request_type.should == :withdraw
  end

  it "should enqueue a new peek request requested by a privileged user" do
    priv_user = add_privileged_user
    ieid = rand(1000)
    now = Time.now

    id = PersistRequest.enqueue_request priv_user, :peek, ieid

    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == true
    just_added.status.should == :enqueued
    just_added.request_type.should == :peek
  end

  it "should not enqueue a new disseminate request requested by a non-privileged user" do
    non_priv_user = add_non_privileged_user
    ieid = rand(1000)
    now = Time.now

    id = PersistRequest.enqueue_request non_priv_user, :disseminate, ieid

    id.should == nil
  end

  it "should not enqueue a new withdraw request requested by a non-privileged user" do
    non_priv_user = add_non_privileged_user
    ieid = rand(1000)
    now = Time.now

    id = PersistRequest.enqueue_request non_priv_user, :withdraw, ieid

    id.should == nil
  end

  it "should not enqueue a new peek request requested by a non-privileged user" do
    non_priv_user = add_non_privileged_user
    ieid = rand(1000)
    now = Time.now

    id = PersistRequest.enqueue_request non_priv_user, :peek, ieid

    id.should == nil
  end

  it "should not enqueue a request if a request of that type is already enqueued for a given ieid" do
    op = add_op_user
    ieid = rand(1000)
    now = Time.now

    id = PersistRequest.enqueue_request op, :disseminate, ieid
    id2 = PersistRequest.enqueue_request op, :disseminate, ieid
    
    id2.should == nil
  end

  it "should allow an authorized operator to approve a withdrawal request" do
    op = add_op_user
    op2 = add_op_user
    now = Time.now
    ieid = rand(1000)

    request_id = PersistRequest.enqueue_request op, :withdraw, ieid

    history_id = PersistRequest.authorize_request(request_id, op2)

    request_record = Request.get(request_id)
    history_record = History.get(history_id)

    request_record.is_authorized.should == true

    history_record.user_id.should == op2.id
    history_record.request_id.should == request_record.id
    history_record.approval_outcome.should == :approved
    history_record.timestamp.to_s.should == now.iso8601
  end

  it "should not allow an operator to approve own requests" do
    op = add_op_user
    now = Time.now
    ieid = rand(1000)

    request_id = PersistRequest.enqueue_request op, :withdraw, ieid

    history_id = PersistRequest.authorize_request(request_id, op)

    request_record = Request.get(request_id)
    history_record = History.get(history_id)

    request_record.is_authorized.should == false

    history_record.user_id.should == op.id
    history_record.request_id.should == request_record.id
    history_record.approval_outcome.should == :denied
    history_record.timestamp.to_s.should == now.iso8601
  end

  it "should not allow a regular user to to approve own requests" do
    user = add_privileged_user
    now = Time.now
    ieid = rand(1000)

    request_id = PersistRequest.enqueue_request user, :withdraw, ieid

    history_id = PersistRequest.authorize_request(request_id, user)

    request_record = Request.get(request_id)
    history_record = History.get(history_id)

    request_record.is_authorized.should == false

    history_record.user_id.should == user.id
    history_record.request_id.should == request_record.id
    history_record.approval_outcome.should == :denied
    history_record.timestamp.to_s.should == now.iso8601
  end

  it "should allow an operator to query for requests by ieid and type" do
    op = add_op_user
    ieid = rand(1000)
    now = Time.now

    request_id = PersistRequest.enqueue_request op, :disseminate, ieid

    request = PersistRequest.query_request op, ieid, :disseminate

    request.should_not == nil
    request.id.should == request_id
  end

  it "should allow an authorized user to query for requests by ieid and type" do
    user = add_privileged_user
    ieid = rand(1000)
    now = Time.now

    request_id = PersistRequest.enqueue_request user, :disseminate, ieid

    request = PersistRequest.query_request user, ieid, :disseminate

    request.should_not == nil
    request.id.should == request_id
  end

  it "should not allow an non-authorized user to query for requests by ieid and type" do
    user = add_privileged_user
    user2 = add_non_privileged_user "FOO"
    ieid = rand(1000)
    now = Time.now

    request_id = PersistRequest.enqueue_request user, :disseminate, ieid

    request = PersistRequest.query_request user2, ieid, :disseminate

    request.should == nil
  end

  it "should allow an operator to delete a request by type and ieid" do
    op = add_op_user
    ieid = rand(1000)
    
    request_id = PersistRequest.enqueue_request op, :disseminate, ieid

    outcome = PersistRequest.delete_request op, ieid, :disseminate

    outcome.should == true
    Request.get(request_id).should == nil
  end

  it "should allow an authorized user to delete a request by type and ieid" do
    user = add_privileged_user
    ieid = rand(1000)
    
    request_id = PersistRequest.enqueue_request user, :disseminate, ieid

    outcome = PersistRequest.delete_request user, ieid, :disseminate

    outcome.should == true
    Request.get(request_id).should == nil
  end

  it "should not allow an non-authorized user to delete requests by ieid and type" do
    user = add_privileged_user
    user2 = add_non_privileged_user "FOO"
    ieid = rand(1000)
    now = Time.now

    request_id = PersistRequest.enqueue_request user, :disseminate, ieid

    request = PersistRequest.delete_request user2, ieid, :disseminate

    request.should == nil
    Request.get(request_id).id.should == request_id
  end

  it "should allow operators to query all requests in a given account" do
    op = add_op_user

    ieid1 = rand(1000)
    ieid2 = rand(1000)
    ieid3 = rand(1000)
    ieid4 = rand(1000)

    request_id1 = PersistRequest.enqueue_request op, :disseminate, ieid1
    request_id2 = PersistRequest.enqueue_request op, :disseminate, ieid2
    request_id3 = PersistRequest.enqueue_request op, :disseminate, ieid3
    request_id4 = PersistRequest.enqueue_request op, :disseminate, ieid4

    set_of_request_ids = [request_id1, request_id2, request_id3, request_id4]

    requests = PersistRequest.query_account op, "FDA"

    requests.length.should == 4

    set_of_request_ids.include?(requests[0].id).should == true
    set_of_request_ids.include?(requests[1].id).should == true
    set_of_request_ids.include?(requests[2].id).should == true
    set_of_request_ids.include?(requests[3].id).should == true
  end

  it "should property return nil on a search for requests on an account with no requests" do
    op = add_op_user

    requests = PersistRequest.query_account op, "FDA"

    requests.length.should == 0
  end

  it "should allow privileged users to query all requests in a given account" do
    user = add_privileged_user

    ieid1 = rand(1000)
    ieid2 = rand(1000)
    ieid3 = rand(1000)
    ieid4 = rand(1000)

    request_id1 = PersistRequest.enqueue_request user, :disseminate, ieid1
    request_id2 = PersistRequest.enqueue_request user, :disseminate, ieid2
    request_id3 = PersistRequest.enqueue_request user, :disseminate, ieid3
    request_id4 = PersistRequest.enqueue_request user, :disseminate, ieid4

    set_of_request_ids = [request_id1, request_id2, request_id3, request_id4]

    requests = PersistRequest.query_account user, "FDA"

    requests.length.should == 4

    set_of_request_ids.include?(requests[0].id).should == true
    set_of_request_ids.include?(requests[1].id).should == true
    set_of_request_ids.include?(requests[2].id).should == true
    set_of_request_ids.include?(requests[3].id).should == true
  end

  it "should not allow non-privileged users to query all requests in a given account" do
    user = add_privileged_user
    user2 = add_non_privileged_user "FOO"

    ieid1 = rand(1000)
    ieid2 = rand(1000)
    ieid3 = rand(1000)
    ieid4 = rand(1000)

    request_id1 = PersistRequest.enqueue_request user, :disseminate, ieid1

    requests = PersistRequest.query_account user2, "FDA"

    requests.should == nil
  end

  it "should allow operators to query all requests in a given ieid" do
    op = add_op_user

    ieid = rand(1000)

    request_id1 = PersistRequest.enqueue_request op, :disseminate, ieid
    request_id2 = PersistRequest.enqueue_request op, :withdraw, ieid
    request_id3 = PersistRequest.enqueue_request op, :peek, ieid

    set_of_request_ids = [request_id1, request_id2, request_id3]

    requests = PersistRequest.query_ieid op, ieid

    requests.length.should == 3

    set_of_request_ids.include?(requests[0].id).should == true
    set_of_request_ids.include?(requests[1].id).should == true
    set_of_request_ids.include?(requests[2].id).should == true
  end

  it "should property return nil on a search for requests on an account with no requests" do
    op = add_op_user

    requests = PersistRequest.query_ieid op, "1"

    requests.length.should == 0
  end

  it "should allow privileged users to query all requests in a given ieid" do
    pending "integration to service that knows what account a given ieid belongs to"
  end

  it "should not allow non-privileged users to query all requests in a given ieid" do
    pending "integration to service that knows what account a given ieid belongs to"
  end
end
