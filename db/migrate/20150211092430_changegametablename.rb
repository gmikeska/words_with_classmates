class Changegametablename < ActiveRecord::Migration
  def change
    	rename_table :game_session, :games
  end
end
