require 'sass/plugin/rack'
require './server'
use Sass::Plugin::Rack

run Game::Server
