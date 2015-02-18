require 'active_record'
#require 'active_record_tasks'
require_relative '../lib/models.rb' # the path to your application file

ActiveRecord::Base.establish_connection(:url => ENV['DATABASE_URL'], :adapter => 'postgresql', :database => 'd3i2apnhscbctr')