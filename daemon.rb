require 'rubygems'
require 'daemons'

pwd = Dir.pwd
Daemons.run_proc('kechimyaku.rb', {:dir_mode => :normal}) do
  Dir.chdir(pwd)
  exec "rbenv sudo ruby kechimyaku.rb -o 172.26.2.193 -p 80"
end