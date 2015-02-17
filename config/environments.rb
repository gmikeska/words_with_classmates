require 'active_record'
require 'active_record_tasks'
require_relative '../lib/models.rb' # the path to your application file


ActiveRecord::Base.establish_connection(
  :adapter => 'postgresql',
  :host     => 'localhost',
  :database => 'wordGame'
)
