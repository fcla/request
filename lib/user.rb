require 'dm-core'
require 'dm-types'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/request.db")

class User
  include DataMapper::Resource

   property :id, Serial
   property :username, String, :nullable => false
   property :password, String, :nullable => false
   property :account, String, :nullable => false
   property :is_operator, Boolean, :nullable => false
   property :can_disseminate, Boolean, :nullable => false
   property :can_withdraw, Boolean, :nullable => false
   property :can_peek, Boolean, :nullable => false

   has n, :requests
   has n, :histories
end
