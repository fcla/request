#!/usr/bin/env ruby

require 'dm-core'
require 'daitss/db/ops/db/operations_agents'
require 'daitss/db/ops/db/operations_events'
require 'daitss/db/ops/db/accounts'
require 'daitss/db/ops/db/projects'
require 'daitss/db/ops/db/keys'
require 'request'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/request.db")

DataMapper.auto_migrate!

# This program is not needed for any spec tests or the operation of the service at all
# Its purpose is simply to populate a table with test data for stand alone operation for demo purposes.


# add an FDA account
a = Account.new
a.attributes = { :name => "FDA",
                 :code => "FDA" }
a.save!

# add an operator user 

o = Operator.new  
o.attributes = { :description => "operator",
  :active_start_date => Time.at(0),
  :active_end_date => Time.now + (86400 * 365),
  :identifier => "operator",
  :first_name => "Op",
  :last_name => "Perator",
  :email => "operator@ufl.edu",
  :phone => "666-6666",
  :address => "FCLA" }

o.account = a

k = AuthenticationKey.new
k.attributes = { :auth_key => Digest::SHA1.hexdigest("operator") }

o.authentication_key = k
o.save!

# add another operator user 

p = Operator.new  
p.attributes = { :description => "operator",
  :active_start_date => Time.at(0),
  :active_end_date => Time.now + (86400 * 365),
  :identifier => "operator_2",
  :first_name => "Op2",
  :last_name => "Perator2",
  :email => "operator2@ufl.edu",
  :phone => "666-6666",
  :address => "FCLA" }

p.account = a

h = AuthenticationKey.new
h.attributes = { :auth_key => Digest::SHA1.hexdigest("operator2") }

p.authentication_key = h
p.save!

# add a contact lacking permissions to request

c = Contact.new
c.attributes = { :description => "contact",
  :active_start_date => Time.at(0),
  :active_end_date => Time.now + (86400 * 365),
  :identifier => "foobar",
  :first_name => "Foo",
  :last_name => "Bar",
  :email => "foobar@ufl.edu",
  :phone => "555-5555",
  :address => "123 Toontown",
  :permissions => [:submit]}


c.account = a

j = AuthenticationKey.new
j.attributes = { :auth_key => Digest::SHA1.hexdigest("foobar") }

c.authentication_key = j
c.save!

# add a contact having permissions to request

d = Contact.new
d.attributes = { :description => "contact",
  :active_start_date => Time.at(0),
  :active_end_date => Time.now + (86400 * 365),
  :identifier => "contact",
  :first_name => "Con",
  :last_name => "Tact",
  :email => "contact@ufl.edu",
  :phone => "555-5555",
  :address => "123 Toontown",
  :permissions => [:disseminate, :withdraw, :peek] }


d.account = a

l = AuthenticationKey.new
l.attributes = { :auth_key => Digest::SHA1.hexdigest("foobar") }

d.authentication_key = l
d.save!
