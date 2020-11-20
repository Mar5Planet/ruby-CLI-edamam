require 'bundler/setup'
require 'rest-client'
require 'pry'
require 'json'
require 'tty-prompt'
require 'colorize'
require 'colorized_string'

Bundler.require

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: "db/development.sqlite3"
)

# ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger = nil
# config.active_record.logger = nil
require_all 'app'

