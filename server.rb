require 'pg'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'sinatra-websocket'
require 'json'
require 'pry-byebug'

require_relative 'config/environments.rb'
set :server, 'thin'
set :sockets, {}
enable :sessions
set :session_secret, ENV['RACK_SECRET']
module Game
	class Server < Sinatra::Application
		before do
			begin
				if session['user_id']
					@user_id = session['user_id']
					@user = User.find(@user_id)
				end
			rescue ActiveRecord::RecordNotFound
				session.clear
				redirect to '/'
			end
		 end
		get '/' do
		  if !request.websocket?
		    erb :index
		  else

		    request.websocket do |ws|
		      ws.onopen do
		        if(@user)
		        	#settings.sockets[@user.username] = ws
		        	#Game::LogStatus.run({message:"Connected"})
		        	#ws.send(JSON.generate({eventName: "console.log", data: "#{@user.username} connected!"}))
		        else
		        	ws.send(JSON.generate({eventName: "console.log", data: "Connected!"}))
		        end
		      end

		      ws.onmessage do |msg|
		      	@message = JSON.parse(msg)
		      	@message['session'] = Session.find(@message['sessionID'])
		      	@message['sockets'] = settings.sockets
		      	@message['user'] = @user
		      	if(@message['eventName'] != 'init')
		      		@action_handler = Game::Actions.new(@message)
		      	end
		      	case @message['eventName']
		      	when "init"
		      		settings.sockets[@user.username] || (settings.sockets[@user.username] = {})
		      		settings.sockets[@user.username][@message['sessionID']] = ws
				when "echo"
					@action_handler.echo(@message)
				when "boardState.update"
					session.change_board_state(@message['x'], @message['y'], @message['letter'])
				when "played"
					@action_handler.play(@message)
				else
				  puts "default case"
				end
		      	
		      end

		      ws.onclose do
		        warn("websocket closed")
		        settings.sockets.delete(ws)
		      end

		    end #request.websocket do
		  end #else
		end #get
		get '/login' do
			
			erb :'auth/login'
		end
		post '/login' do
			@user = User.find_by username: params['username']

			if @user && @user.password = params['password']
				session[:user_id] = @user.id
				redirect '/home'

			else
				flash[:loginmsg] = "Username or password error."
				redirect '/login'
			end
		end
		post '/signup' do

			u = User.find_by username: params['username']

			if(!u)
				@user = User.new
				if(params['password'] == params['confirm'])
					@user.username = params['username']
					@user.password = params['password']
					@user.scores = []
					@user.save()
					session[:user_id] = @user.id
					redirect '/home'
				else
					flash[:loginmsg] = "The passwords entered do not match."
					redirect '/signup'
				end
			else
				flash[:loginmsg] = "Sorry! That username is taken. Please pick another."
				redirect '/signup'
			end
		end
		get '/signup' do

			erb :'auth/signup'
		end
		get '/user/:username' do
			@u = User.find_by username: params['username']
			erb :'user/profile'
		end
		get '/game/new' do
			@allusers = User.where("id != #{@user.id}")
			erb :'game/new'
		end
		get '/game/:id/show' do
			@game_id = params['id']
			@game_session = Session.find(params['id'])
			@users = @game_session.users
			@rack =  @game_session.letter_bag.rack[@user.username]
			# binding.pry()
			erb :'game/show'
		end
		post '/game/new' do
			u = User.find params['user']
			game = Game::Session.new
			game.save
			game.users << u
			game.users << @user
			game.save
			game.letter_bag = LetterBag.create
			game.letter_bag.init_tiles
			game.letter_bag.played_words = []
			game.letter_bag.init_rack
			game.letter_bag.add_rack(@user.username)
			game.letter_bag.add_rack(u.username)
			game.letter_bag.draw(@user.username, 7)
			game.letter_bag.draw(u.username, 7)
			game.init_board_state
			game.next_player()
			#binding.pry()
			game.letter_bag.save()
			redirect "/game/#{game.id}/show"
		end
		get '/logout' do
			session.clear
			redirect '/'
		end
		get '/home' do

			erb :'user/home'
		end
	end #class
end #module