class Mygame < ActiveRecord::Base
  belongs_to :game
  belongs_to :user
  validates_presence_of :game, :user
end
