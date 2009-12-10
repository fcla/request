require 'persist_request'
require 'pp'

describe PersistRequest do

  before(:each) do
    @request = PersistRequest.new

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

  def add_non_privileged_user
    user = User.new

    user.attributes = {
      :username => "nopriv",
      :password => "nopriv",
      :account => "FDA",
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

    id = @request.enqueue_request op, :disseminate, ieid
    
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

    id = @request.enqueue_request op, :withdraw, ieid
    
    just_added = Request.get(id)

    just_added.should_not == nil
    just_added.ieid.should == ieid.to_s
    just_added.timestamp.to_s.should == now.iso8601
    just_added.is_authorized.should == false
    just_added.status.should == :enqueued
    just_added.request_type.should == :withdraw
  end
end
