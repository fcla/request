require 'user'
require 'request'
require 'history'

class InvalidRequestType < StandardError; end

class PersistRequest
  def enqueue_request user, type, ieid
    r = Request.new
    now = Time.now

    # raise error if specified type is not supported
    raise InvalidRequestType, "#{type} is not a supported request type" unless supported? type

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
  end

  private

  # returns true if type is supported
  def supported? type
    type == :withdraw or type == :disseminate or type == :peek
  end
end
