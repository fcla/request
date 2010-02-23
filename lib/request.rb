require 'dm-core'
require 'dm-types'

class Request
  include DataMapper::Resource

   property :id, Serial
   property :ieid, String, :nullable => false
   property :account, String, :nullable => false
   property :timestamp, DateTime, :nullable => false
   property :is_authorized, Boolean, :nullable => false
   property :status, Enum[:enqueued, :released_to_workspace], :default => :enqueued
   property :request_type, Enum[:disseminate, :withdraw, :peek]
   property :agent_identifier, String, :nullable => false
end
