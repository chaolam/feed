require 'ostruct'
FBConf = OpenStruct.new(YAML.load_file(Rails.root.to_s + '/config/fbconf.yml')[ENV['RAILS_ENV'] || 'development'].symbolize_keys)
