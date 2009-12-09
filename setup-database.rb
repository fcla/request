#!/usr/bin/env ruby

require 'dm-core'
require 'user'
require 'request'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/request.db")

DataMapper.auto_migrate!
