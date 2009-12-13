require 'user'

def add_op_user
  user = User.new

  user.attributes = {
    :username => "op",
    :password => "op",
    :account => "FDA",
    :is_operator => true,
    :can_disseminate => true,
    :can_withdraw => false,
    :can_peek => false
  }

  user.save

  return user
end

def add_privileged_user
  user = User.new

  user.attributes = {
    :username => "priv",
    :password => "priv",
    :account => "FDA",
    :is_operator => false,
    :can_disseminate => true,
    :can_withdraw => true,
    :can_peek => true
  }

  user.save

  return user
end

def add_non_privileged_user account = "FDA"
  user = User.new

  user.attributes = {
    :username => "nopriv",
    :password => "nopriv",
    :account => account,
    :is_operator => false,
    :can_disseminate => false,
    :can_withdraw => false,
    :can_peek => false
  }

  user.save

  return user
end

