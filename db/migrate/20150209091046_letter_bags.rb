class LetterBags < ActiveRecord::Migration
  def change
    create_table :letter_bags do |t|
    	t.text :tile_map
    	t.text :rack
    end
  end
end
