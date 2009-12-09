require 'dm-core'
require 'dm-types'
require 'user'
require 'request'

class History
  include DataMapper::Resource

   property :id, Serial
   property :timestamp, DateTime, :nullable => false

   belongs_to :user
   belongs_to :request
end
