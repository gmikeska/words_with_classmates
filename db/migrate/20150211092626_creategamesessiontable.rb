class Creategamesessiontable < ActiveRecord::Migration
  def change
    create_table :game_session do |t|
    	t.integer :user_id
    	t.integer :game_id
    end
  end
end
