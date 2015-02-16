module Game
	BOARD_MAP = [
		["tw","xx","xx","dl","xx","xx","xx","tw","xx","xx","xx","dl","xx","xx","tw"],
		["xx","dw","xx","xx","xx","tl","xx","xx","xx","tl","xx","xx","xx","dw","xx"],
		["xx","xx","dw","xx","xx","xx","dl","xx","dl","xx","xx","xx","dw","xx","xx"],
		["dl","xx","xx","dw","xx","xx","xx","dl","xx","xx","xx","dw","xx","xx","dl"],
		["xx","xx","xx","xx","dw","xx","xx","xx","xx","xx","dw","xx","xx","xx","xx"],
		["xx","tl","xx","xx","xx","tl","xx","xx","xx","tl","xx","xx","xx","tl","xx"],
		["xx","xx","dl","xx","xx","xx","dl","xx","dl","xx","xx","xx","dl","xx","xx"],
		["tw","xx","xx","dl","xx","xx","xx","dw","xx","xx","xx","dl","xx","xx","tw"],
		["xx","xx","dl","xx","xx","xx","dl","xx","dl","xx","xx","xx","dl","xx","xx"],
		["xx","tl","xx","xx","xx","tl","xx","xx","xx","tl","xx","xx","xx","tl","xx"],
		["xx","xx","xx","xx","dw","xx","xx","xx","xx","xx","dw","xx","xx","xx","xx"],
		["dl","xx","xx","dw","xx","xx","xx","dl","xx","xx","xx","dw","xx","xx","dl"],
		["xx","xx","dw","xx","xx","xx","dl","xx","dl","xx","xx","xx","dw","xx","xx"],
		["xx","dw","xx","xx","xx","tl","xx","xx","xx","tl","xx","xx","xx","dw","xx"],
		["tw","xx","xx","dl","xx","xx","xx","tw","xx","xx","xx","dl","xx","xx","tw"],
		]
	require 'json'
	class LetterBag < ActiveRecord::Base
		serialize :tile_map, JSON
		serialize :rack, JSON
		belongs_to :session, :class_name => 'Game::Session'

		def init_tiles
							# English-language editions of Scrabble contain 100 letter tiles, in the following distribution:
				# 2 blank tiles (scoring 0 points)
				# 1 point: E ×12, A ×9, I ×9, O ×8, N ×6, R ×6, T ×6, L ×4, S ×4, U ×4
				# 2 points: D ×4, G ×3
				# 3 points: B ×2, C ×2, M ×2, P ×2
				# 4 points: F ×2, H ×2, V ×2, W ×2, Y ×2
				# 5 points: K ×1
				# 8 points: J ×1, X ×1
				# 10 points: Q ×1, Z ×1
		
			self.tile_map = {
				'A' => {'value' => '1', 'count' => 9},
				'B' => {'value' => '3', 'count' => 2},
				'C' => {'value' => '3', 'count' => 2},
				'D' => {'value' => '2', 'count' => 4},
				'E' => {'value' => '1', 'count' => 12},
				'F' => {'value' => '4', 'count' => 2},
				'G' => {'value' => '2', 'count' => 3},
				'H' => {'value' => '4', 'count' => 2},
				'I' => {'value' => '1', 'count' => 9},
				'J' => {'value' => '8', 'count' => 1},
				'K' => {'value' => '5', 'count' => 1},
				'L' => {'value' => '1', 'count' => 4},
				'M' => {'value' => '3', 'count' => 2},
				'N' => {'value' => '1', 'count' => 6},
				'O' => {'value' => '1', 'count' => 8},
				'P' => {'value' => '3', 'count' => 2},
				'Q' => {'value' => '10', 'count' => 1},
				'R' => {'value' => '1', 'count' => 6},
				'S' => {'value' => '1', 'count' => 4},
				'T' => {'value' => '1', 'count' => 6},
				'U' => {'value' => '1', 'count' => 4},
				'V' => {'value' => '4', 'count' => 2},
				'W' => {'value' => '4', 'count' => 2},
				'X' => {'value' => '8', 'count' => 1},
				'Y' => {'value' => '4', 'count' => 2},
				'Z' => {'value' => '10', 'count' => 1},
				'_' => {'value' => '0', 'count' => 2}
			}
		end
		def init_rack
			self.rack = {}
		end
		def add_rack(username)
			self.rack[username] = []
			self.save
		end

		def get_rack(username)
			self.rack[username]
		end
		def remove_racked_letter(username, letter)
			self.rack[username].each do |obj|
				if(obj["letter"] = letter)
					self.rack[username].delete(obj)
					self.save
					return true
				end
			end
		end
		def add_racked_letter(username, letter)
			self.rack[username].push(letter)
		end
		def draw(username, n)

			letters = []
			n.times do
				
				l = countFromTop(rand(remainingTiles))
				l = LetterTile.new(l['letter'], l['value'])
				self.rack[username].push(l)
				self.tile_map[l.letter]['count'] = self.tile_map[l.letter]['count'] - 1
			end
			self.save
		end
		def remainingTiles
			count = 0;
			self.tile_map.each do |char, obj|
				count = count + obj['count']
			end
			
			return count;
		end
		def list_players
			self.rack.keys
		end
		def make_tile(letter)
			lt = LetterTile.new(letter, tile_map[letter]['value'])
			# lt.game_board = self.session.game_board
			return lt
		end
		def countFromTop(n)
				letterList = []
			self.tile_map.each do |k,v|
				v['count'].times do
					letterList.push(k)
				end
			end
			

			result = self.tile_map[letterList[n]].clone
			result['letter'] = letterList[n]
			return result
		end
	end

	class LetterTile
		
		attr_reader :letter, :value
		attr_accessor :x, :y, :is_new
		
		def initialize(letter, value)
			@letter = letter
			@value = value
		end

		def get_tile(game_board, direction)
			case direction
			when :up
				return game_board[@y-1][@x]
			when :down
				return game_board[@y+1][@x]
			when :left
				return game_board[@y][@x-1]
			else
				return game_board[@y][@x+1]
			end	
		
		end
		def get_multiplier
			return BOARD_MAP[@y][@x]
		end
		def get_score	
			if BOARD_MAP[@y][@x] == 'dl' && @is_new
				return value.to_i*2
			elsif BOARD_MAP[@y][@x] == 'tl' && @is_new
				return value.to_i*3
			else
				return value.to_i
			end
		end
		def words(game_board, restrict = :both)
			found_words = []
			
			if(restrict != :horizontal)
				first = self
				t = first.get_tile(game_board, :up)
				while(!t.nil? && first.x >0)
					p t
					first = t
					if(t.is_new && restrict == :both)
						found_words = found_words + t.words(game_board, :horizontal)
					end
					t = first.get_tile(game_board, :up)
				end
				#first.is_new = false
				word = []
				t = first
				while(!t.nil?)
					first = t
					word.push(t)
					t = first.get_tile(game_board, :down)
				end
				if(!word.nil? && word.length >1)
					found_words.push(word)
				end
			end


			if(restrict != :vertical)
				first = self
				t = first.get_tile(game_board, :left)
				while(!t.nil? && first.x >0)
					first = t
					if(t.is_new && restrict == :both)
						found_words = found_words + t.words(game_board, :vertical)
					end
					t = first.get_tile(game_board, :left)
				end
				#first.is_new = false
				word = []
				t = first
				while(!t.nil?)
					first = t
					word.push(t)
					t = first.get_tile(game_board, :right)
				end
				if(!word.nil? && word.length >1)
					found_words.push(word)
				end
			end
			return found_words
		end
	end

	class Word

		attr_reader :score, :text
		
		def initialize letter_array
			@letters = letter_array
			@multipliers = []
			@score = 0
			@text = ""
			@letters.each do |tile|
				s = tile.get_multiplier
				@score = @score+tile.get_score
				if((s == 'tw' || s == 'dw') && tile.is_new)
 					@multipliers.push s
				end
				@text = @text+tile.letter
			end

			@score = @multipliers.inject(@score) do |total, m|
				p m
				if m == "tw"
					total * 3
				elsif m == "dw"
					total * 2
				else
					total
				end
			end
		end
	end
	class Dictionary

		def initialize(fname)
			p "Loading Dictionary"
			f = File.open(Dir.pwd+'/lib/'+fname)
			@wordlist = []

			f.each_line do |x|
			  @wordlist.push(x.chomp())
			end

			p 'Dictionary Loaded'
		end

		def check(word)
			return @wordlist.include?(word)
		end

	end
end	