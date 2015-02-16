module Game
	class UserSession < ActiveRecord::Base
		belongs_to :user, :class_name => 'Game::User'
		belongs_to :session, :class_name => 'Game::Session'
	end
end