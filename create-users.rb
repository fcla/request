#!/usr/bin/env ruby

require 'user'
require 'history'
require 'pp'
require 'request_handler'

user_1 = User.new
user_2 = User.new

user_1.attributes = {
  :username => "op",
  :password => "op",
  :account => "FDA",
  :is_operator => true,
  :can_disseminate => true,
  :can_withdraw => false,
  :can_peek => false
}

user_2.attributes = {
  :username => "user",
  :password => "user",
  :account => "FDA",
  :is_operator => false,
  :can_disseminate => true,
  :can_withdraw => false,
  :can_peek => false
}

user_1.save!
user_2.save!

