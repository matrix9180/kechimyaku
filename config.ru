module Gollum
  Gollum::GIT_ADAPTER = "rugged"
end

require File.expand_path('kechimyaku', File.dirname(__FILE__))
require 'gollum/app'


configure :development do
  set :database, 'sqlite3:db/database.db'
end

wiki_options = {
  :live_preview  => true,
  :allow_uploads => true,
  :allow_editing => true,
}
wiki_options[:base_path] = "wiki"
wiki_options[:css] = true
wiki_options[:js] = true
wiki_options[:emoji] = true
wiki_options[:live_preview] = false
wiki_options[:allow_uploads]    = true
wiki_options[:per_page_uploads] = false
wiki_options[:mathjax] = true
wiki_options[:h1_title] = true
wiki_options[:show_all] = true
wiki_options[:collapse_tree] = true
wiki_options[:user_icons] = :dir
wiki_options[:mathjax_config] = 'mathjax.config.js'
wiki_options[:plantuml_url] = ''
wiki_options[:template_dir] = "views/gollum_templates"


Precious::App.set(:gollum_path, "wiki_repo/")
Precious::App.set(:wiki_options, wiki_options)
Precious::App.settings.mustache[:templates] = wiki_options[:template_dir] if wiki_options[:template_dir]

map '/wiki' do
  run Precious::App
end

run Kechimyaku