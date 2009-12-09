#!/usr/bin/env ruby

require 'user'
require 'pp'

user_1 = User.new
user_2 = User.new
user_3 = User.new

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
  :username => "sally",
  :password => "mae",
  :account => "FDA",
  :is_operator => false,
  :can_disseminate => false,
  :can_withdraw => false,
  :can_peek => false
}

user_3.attributes = {
  :username => "cando",
  :password => "rizzian",
  :account => "FDA",
  :is_operator => false,
  :can_disseminate => true,
  :can_withdraw => true,
  :can_peek => true
}

user_1.save
user_2.save
user_3.save

pp User.all
