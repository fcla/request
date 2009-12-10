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

    # authorization

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

end
