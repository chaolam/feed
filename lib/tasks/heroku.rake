namespace :heroku do
  task :config do
    puts "Reading config/fbconf.yml and sending config vars to Heroku..."
    CONFIG = YAML.load_file('config/fbconf.yml')['production'] rescue {}
    command = "heroku config:add"
    CONFIG.each {|key, val| command << " #{key}=#{val} " if val }
    system command
  end
end