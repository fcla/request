require 'db/int_entity'
require 'db/representation'
require 'db/datafiles_representations'
require 'db/datafile'
require 'db/datafile_severe_element'
require 'db/severe_element'
require 'db/objectformat'
require 'db/format'
require 'db/document'
require 'db/brokenlinks'
require 'db/image'
require 'db/text'
require 'db/bitstream'
require 'db/message_digest'
require 'db/audio'

def add_account name = "FDA", code = "FDA"
  a = Account.new
  a.attributes = { :name => name,
                   :code => code }
  a.save!

  return a
end

def add_operator account, identifier = "operator", password = "operator"
  o = Operator.new  

  o.attributes = { :description => "operator",
    :active_start_date => Time.at(0),
    :active_end_date => Time.now + (86400 * 365),
    :identifier => identifier,
    :first_name => "Op",
    :last_name => "Perator",
    :email => "operator@ufl.edu",
    :phone => "666-6666",
    :address => "FCLA" }

  o.account = account

  k = AuthenticationKey.new
  k.attributes = { :auth_key => Digest::SHA1.hexdigest(password) }

  o.authentication_key = k
  o.save!
end


def add_contact account, permissions = [:disseminate, :withdraw, :peek], identifier = "contact", password = "foobar"
  c = Contact.new
  c.attributes = { :description => "contact",
    :active_start_date => Time.at(0),
    :active_end_date => Time.now + (86400 * 365),
    :identifier => identifier,
    :first_name => "Foo",
    :last_name => "Bar",
    :email => "foobar@ufl.edu",
    :phone => "555-5555",
    :address => "123 Toontown",
    :permissions => permissions  }

  c.account = account

  j = AuthenticationKey.new
  j.attributes = { :auth_key => Digest::SHA1.hexdigest(password) }

  c.authentication_key = j
  c.save!
end

def add_service account, identifier="http://request.dev.fcla.edu", password = "request", description = "d2 request service"
  s = Service.new
  s.attributes = { :description => description,
                   :active_start_date => Time.at(0),
                   :active_end_date => Time.now + (86400 * 365),
                   :identifier => identifier }

  s.account = account

  j = AuthenticationKey.new
  j.attributes = { :auth_key => Digest::SHA1.hexdigest(password) }

  s.authentication_key = j
  s.save!
end

def add_program account, identifier="bianchi:/Users/manny/code/git/request/poll-workspace", password = "poller", description = "Request service poller"
  p = Program.new
  p.attributes = { :description => description,
                   :active_start_date => Time.at(0),
                   :active_end_date => Time.now + (86400 * 365),
                   :identifier => identifier }

  p.account = account

  j = AuthenticationKey.new
  j.attributes = { :auth_key => Digest::SHA1.hexdigest(password) }

  p.authentication_key = j
  p.save!

  return p
end

def add_project account, name = "PRJ", code = "PRJ"
  p = Project.new
  p.attributes = { :name => name,
                   :code => code }

  p.account = account
  p.save!

  return p
end

def add_intentity ieid, project
  i = Intentity.new

  i.attributes = { :id => ieid,
                   :original_name => "test package",
                   :entity_id => "test",
                   :volume => "vol",
                   :issue => "issue",
                   :title => "title" }

  i.project = project
  i.save!

  return i
end
