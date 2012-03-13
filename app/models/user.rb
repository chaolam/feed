class User < ActiveRecord::Base
  has_many :mygames
  has_many :games, :through=>:mygames
end
