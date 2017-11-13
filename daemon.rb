require 'rubygems'
require 'daemons'

pwd = Dir.pwd
Daemons.run_proc('kechimyaku.rb', {:dir_mode => :normal}) do
  Dir.chdir(pwd)
  exec "ruby kechimyaku.rb"
end