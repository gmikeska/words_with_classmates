require 'bcrypt'
module Game
	class User < ActiveRecord::Base
		serialize :scores
		validates :username, uniqueness: true
		has_many :user_sessions, :class_name => 'Game::UserSession'
		has_many :sessions, through: :user_sessions, :class_name => 'Game::Session'
	include BCrypt
	  def password
	    @password ||= Password.new(password_hash)
	  end

	  def password=(new_password)
	    @password = Password.create(new_password)
	    self.password_hash = @password
	  end

	def login
	  @user = User.find_by_email(params[:email])
	  if @user.password == params[:password]
	    give_token
	  else
	    redirect_to home_url
	  end
	end


	end
end