#!/usr/bin/env ruby

require 'user'
require 'history'
require 'pp'
require 'request_handler'

user_1 = User.new
user_2 = User.new

user_1.attributes = {
  :username => "foo",
  :password => "bar",
  :account => "FDA",
  :is_operator => true,
  :can_disseminate => true,
  :can_withdraw => false,
  :can_peek => false
}

user_2.attributes = {
  :username => "foo",
  :password => "bar",
  :account => "FDA",
  :is_operator => true,
  :can_disseminate => true,
  :can_withdraw => false,
  :can_peek => false
}

user_1.save!
user_2.save!

ieid1 = rand(1000)
ieid2 = rand(1000)
ieid3 = rand(1000)
ieid4 = rand(1000)

# disseminate then peek for 1
RequestHandler.enqueue_request user_1, :disseminate, ieid1
sleep 2
RequestHandler.enqueue_request user_1, :peek, ieid1

# not authorized withdraw request for 2
RequestHandler.enqueue_request user_1, :withdraw, ieid2

# authorized withdraw request for 3
id = RequestHandler.enqueue_request user_1, :withdraw, ieid3
RequestHandler.authorize_request id, user_2

# peek for 4
RequestHandler.enqueue_request user_1, :peek, ieid4

