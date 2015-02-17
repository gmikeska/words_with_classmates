require 'json'
module Game
	class Session < ActiveRecord::Base
		serialize :board_state
		has_many :user_sessions, :class_name => 'Game::UserSession'
		has_many :users, through: :user_sessions, :class_name => 'Game::User'
		has_one :letter_bag
		def init_board_state
			self.board_state = []
			15.times do |x|
				ar = []
				15.times do |y|
					ar.push(nil)
				end
				self.board_state.push(ar)
			end
			self.current_player = self.list_players[0]
			self.save()
		end
		def list_opponents(username)
			self.list_players-[username]
		end
		def list_players
			self.letter_bag.list_players
		end
		def next_player
			i = self.list_players.find_index(self.current_player)+1
			if(i >= self.list_players.length)
				self.current_player = self.list_players[0]
			else
				self.current_player = self.list_players[i]
			end
			self.save
			return self.current_player
		end
		def get_rack(username)
			return self.letter_bag.get_rack(username)
		end
		def lock_tiles
			self.board_state.each do |y|
				y.each do |x|
					if !x.nil?
						x.is_new = false
						p x.letter
					end
				end
			end
			self.save
		end
		def reject
			self.board_state.each_index  do |y|
				self.board_state[y].each_index do |x|
					i = self.board_state[y][x]
					if !(i.nil?) && i.is_new
						self.letter_bag.get_rack(self.current_player).push(i)
						self.board_state[y][x] = nil
					end
				end
			end
			self.save
		end
		def game_board
			return self.board_state
		end
		def letter_at(x,y)
			return self.board_state[y][x]
		end
		def remove_racked_letter(letter)
			self.letter_bag.remove_racked_letter(self.current_player, letter)
		end
		def fill_rack(username)
			n = (7 - self.letter_bag.get_rack(username).length)
			self.letter_bag.draw(username, n)
			self.letter_bag.save
			self.save

			return self.get_rack(username)
		end
		def change_board_state(user_id, x, y, letter)
			u = User.find(user_id)
			if(self.current_player == u.username)
				tile = self.letter_bag.make_tile(letter)
				tile.is_new = true

				if(self.board_state[y][x].nil?)
					self.board_state[y][x] = tile
				end
				tile.x = x
				tile.y = y
				self.save
				return true
			else
				return false
			end
		end
	end
end