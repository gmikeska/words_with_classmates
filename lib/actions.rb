module Game
	class Actions
		def initialize(params)
			@sockets  = params['sockets']
			@session = params['session']
			@user = params['user']
			@opponents = @session.list_opponents(@user.username)
			@ws = @sockets[@user.username][@session.id]
			@wordlist = Game::Dictionary.new('words.txt')
		end
		def echo(params)
			data = {eventName: "console.log", data: params['data']}
			self.sendBack(data)
			data[:data] = @user.username+":"+data[:data]
			self.sendToOpponents(data)
		end
		def broadcast(data)
			self.sendBack(data)
			self.sendToOpponents(data)
		end
		def sendBack(data)
			@ws.send(JSON.generate(data))
		end
		def sendToOpponents(data)
			@opponents.each do |username|
					if(@sockets[username] && @sockets[username][@session.id])
						@sockets[username][@session.id].send(JSON.generate(data))
					end
			end
		end
		def play(params)
			board = @session.game_board
			tiles = params['tiles']
			newRack = []
			p tiles
			moves = tiles.inject(true) do |result, tile|
				result && @session.change_board_state(@user.id, tile['x'], tile['y'], tile['letter'])
			end
			tiles.map! do |t|

					t = {"x"=>t['x'], "y"=>t['y'], "letter"=>@session.letter_bag.make_tile(t['letter'])}
			end

			words = board[tiles.last['y']][tiles.last['x']].words(board).map do |w|
					word = Game::Word.new(w)
					@wordlist.check(word.text)
					{text: word.text, score:word.score}
			end
			invalid = []
			valid = true
			words.each do |w|
				if(!@wordlist.check(w[:text]))
					invalid.push(w[:text])
					valid = false
				end
			end
			p invalid
			p valid

			if(valid)
				params['tiles'].each do |tile|
					@session.remove_racked_letter tile['letter'] 
					@session.save
				end
				new_letters = @session.fill_rack(@user.username).to_json
				self.sendBack({eventName:"rack.update", data:new_letters})

				self.broadcast({eventName:'words.played', data:{player: @session.current_player, words:words}})
				@session.lock_tiles

				self.sendToOpponents({eventName:"boardState.update", data:tiles.to_json})
				new_player = @session.next_player()
				self.broadcast({eventName:"currentUser.update", data:new_player})
			else
				@session.reject()
				self.sendBack({eventName:"words.reject", data:invalid })
			end
		end
	end
end