require 'user'
require 'request'
require 'history'

class InvalidRequestType < StandardError; end

class PersistRequest

  # enqueues a new request. 
  # If authorized, returns the id of the new request. Otherwise, returns nil

  def self.enqueue_request user, type, ieid

    # raise error if specified type is not supported
    raise InvalidRequestType, "#{type} is not a supported request type" unless supported? type

    # if request already enqueued or in process for given ieid, refuse to enqueue new request
    
    return nil if already_enqueued? ieid, type

    if authorized_to_submit? user, type
      r = Request.new
      now = Time.now

      # if the request type is withdrawal, it needs to be authorized. Otherwise, it doesn't.
      if type == :withdraw
        auth = false
      else
        auth = true
      end

      r.attributes = {
        :ieid => ieid,
        :timestamp => now,
        :is_authorized => auth,
        :status => :enqueued,
        :request_type => type
      }

      user.requests << r

      r.save!
      user.save!

      return r.id
    else
      return nil
    end
  end

  # authorize a request, and save record of authorization outcome. 
  # returns primary key to outcome record
  
  def self.authorize_request request_id, authorizing_user
    request = Request.get(request_id)
    history = History.new
    now = Time.now

    if authorizing_user.is_operator and request.user_id != authorizing_user.id
      request.is_authorized = true
      approval = :approved
    else
      approval = :denied
    end

    history.attributes = {
      :timestamp => now,
      :approval_outcome => approval
    }

    authorizing_user.histories << history
    request.histories << history

    authorizing_user.save!
    request.save!
    history.save!

    return history.id
  end

  # if one exists, returns any pending request associated with ieid ieid of type type.
  # if user doesn't have permission, or if no such request exists, returns nil.
  
  def self.query_request requesting_user, ieid, type
    request = Request.first(:ieid => ieid, :request_type => type, :status => :enqueued)

    # if user is not an operator, check if account of requesting user matches account of submitting user
    
    if request and requesting_user.is_operator == false
      original_user = User.get(request.user_id)

      if original_user.account == requesting_user.account
        return request
      else
        return nil
      end
    else
      return request
    end
  end

  # if one exists, deletes any pending request associated with ieid ieid of type type.
  # if user doesn't have permission, or if no such request exists, returns nil.
  
  def self.delete_request requesting_user, ieid, type
    request = query_request requesting_user, ieid, type

    return nil unless request

    return request.destroy!
  end

  private

  # returns true if type is supported
  def self.supported? type
    type == :withdraw or type == :disseminate or type == :peek
  end

  def self.authorized_to_submit? user, type
    return true if user.is_operator

    return true if type == :disseminate and user.can_disseminate

    return true if type == :withdraw and user.can_withdraw

    return true if type == :peek and user.can_peek

    return false
  end

  def self.already_enqueued? ieid, type
    Request.first(:ieid => ieid, :request_type => type, :status => :enqueued)
  end

end
