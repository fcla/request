require 'db/request'
require 'db/operations_agents'
require 'db/operations_events'
require 'db/accounts'
require 'db/projects'
require 'db/keys'
require 'db/sip'

class InvalidRequestType < StandardError; end
class NotAuthorized < StandardError; end
class NoSuchIntEntity < StandardError; end

# TODO: test how this will behave if a service or program is passed in as the agent
class RequestHandler

  # enqueues a new request. 
  # If authorized, returns the id of the new request.
  # Raises exception if not authorized.
  # Returns nil if a request of the same time is already enqueued for specified ieid.
  # Adds OperationsEvent

  def self.enqueue_request agent_identifier, type, ieid
    sip_record = SubmittedSip.first(:ieid => ieid)
    raise NoSuchIntEntity unless sip_record

    # raise error if specified type is not supported
    # TODO: move to validation in model?
    raise InvalidRequestType, "#{type} is not a supported request type" unless supported? type

    # if request already enqueued or in process for given ieid, refuse to enqueue new request
    return nil if already_enqueued? sip_record, type

    agent = OperationsAgent.first(:identifier => agent_identifier)

    if authorized_to_submit? agent, type and (sip_record.project.account.code == agent.account.code or agent.type == Operator)
      r = Request.new
      now = Time.now

      # if the request type is withdrawal, it needs to be authorized. Otherwise, it doesn't.
      if type == :withdraw
        auth = false
      else
        auth = true
      end

      r.attributes = {
        :timestamp => now,
        :is_authorized => auth,
        :status => :enqueued,
        :request_type => type,
      }

      r.operations_agent = agent
      r.account = agent.account
      r.submitted_sip = sip_record

      r.save!

      add_op_event agent, sip_record, "Request Submission", "request_type: #{type}, request_id: #{r.id}"

      return r.id
    else
      raise NotAuthorized
    end
  end

  # authorize a request, and save record of authorization outcome. 
  # raises exception if user is not authorized to authorize request
  # Adds OperationsEvent
  
  def self.authorize_request request_id, authorizing_agent_identifier
    request = Request.get(request_id)
    now = Time.now
    sip = request.submitted_sip

    authorizing_agent = OperationsAgent.first(:identifier => authorizing_agent_identifier)

    if authorizing_agent and authorizing_agent.type == Operator and request.operations_agent.identifier != authorizing_agent.identifier
      request.is_authorized = true

      add_op_event authorizing_agent, sip, "Request Approval", "authorizing_agent: #{authorizing_agent.identifier}, request_id: #{request.id}"
    else
      raise NotAuthorized
    end

    request.save!
  end

  # if one exists, returns any pending request associated with ieid ieid of type type.
  # if no such request exists, returns nil.
  # if user is not authorized, exception is raised
  
  def self.query_request requesting_agent_identifier, ieid, type
    sip = SubmittedSip.first(:ieid => ieid)

    return nil unless sip

    request = sip.requests.first(:request_type => type, :status => :enqueued)

    # if user is not an operator, check if account of requesting user matches account of the request
    
    agent = OperationsAgent.first(:identifier => requesting_agent_identifier)

    if request and agent
      if request.account.code == agent.account.code or agent.type == Operator
        return request
      else
        raise NotAuthorized
      end
    else
      return nil
    end
  end

  # if one exists, deletes any pending request associated with ieid ieid of type type.
  # if user doesn't have authorization, raise error.
  # if no such request exists, returns nil.
  # Adds OperationsEvent
  
  def self.delete_request requesting_agent_identifier, ieid, type
    request = query_request requesting_agent_identifier, ieid, type
    agent = OperationsAgent.first(:identifier => requesting_agent_identifier)

    return nil unless request

    sip = request.submitted_sip

    add_op_event agent, sip, "Request Deletion", "request_id: #{request.id}"

    return request.destroy!
  end

  # returns the set of all requests (pending and not) for a given account
  # raises exception if user does not have authorization
  # returns empty array if result set is empty
  
  def self.query_account requesting_agent_identifier, account
    agent = OperationsAgent.first(:identifier => requesting_agent_identifier)

    if agent and (agent.type == Operator or account == agent.account.code)
      return Request.all(:account => {:code => account})
    else
      raise NotAuthorized
    end
  end

  # returns the set of all requests (pending and not) for a given ieid 
  # raises exception if user does not have authorization
  # returns empty array if result set is empty

  def self.query_ieid requesting_agent_identifier, ieid
    agent = OperationsAgent.first(:identifier => requesting_agent_identifier)
    sip = SubmittedSip.first(:ieid => ieid)

    raise NotAuthorized unless agent
    raise NoSuchIntEntity unless sip
    raise NotAuthorized unless sip.project.account.code == agent.account.code or agent.type == Operator

    return sip.requests
  end

  # sets status of request to :released_to_workspace, dequeing it

  def self.dequeue_request request_id, operations_agent_identifier
    r = Request.get(request_id)
    agent = OperationsAgent.first(:identifier => operations_agent_identifier)
    sip = r.submitted_sip

    add_op_event agent, sip, "Request Released to Workspace", "request_id: #{r.id}"

    r.status = :released_to_workspace
    r.save!
  end

  private

  # inserts an op event
  def self.add_op_event agent, sip, event_name, notes
    e = OperationsEvent.new

    e.attributes = { :timestamp => Time.now,
                     :event_name => event_name,
                     :notes => notes }

    e.operations_agent = agent
    e.submitted_sip = sip

    e.save!
  end

  # returns true if type is supported
  def self.supported? type
    type == :withdraw or type == :disseminate or type == :peek
  end

  # returns true if agent is authorized to submit request, false otherwise
  def self.authorized_to_submit? agent, type
    if agent and agent.type == Operator
      return true
    elsif agent and agent.type == Contact
      return true if type == :disseminate and agent.permissions.include?(:disseminate)
      return true if type == :withdraw and agent.permissions.include?(:withdraw)
      return true if type == :peek and agent.permissions.include?(:peek)

      return false
    else
      return false
    end
  end

  def self.already_enqueued? sip, request_type
    sip.requests.all(:request_type => request_type, :status => :enqueued).length != 0
  end
end
