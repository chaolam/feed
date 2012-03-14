require 'ostruct'
config = (YAML.load_file(Rails.root.to_s + '/config/fbconf.yml')[Rails.env] rescue {}).merge(ENV)
FBConf = OpenStruct.new(config)
