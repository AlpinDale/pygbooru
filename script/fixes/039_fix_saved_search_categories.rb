#!/usr/bin/env ruby

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment'))

ActiveRecord::Base.connection.execute("set statement_timeout = 0")

CurrentUser.user = User.admins.first
CurrentUser.ip_addr = "127.0.0.1"

SavedSearch.where("category is not null and category <> ''").find_each do |ss|
  print ss.category + " -> "
  ss.normalize
  puts ss.category
  ss.save
end
