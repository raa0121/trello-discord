require 'bundler'
Bundler.require

require './web'
$stdout.sync = true
run TrelloDiscord
