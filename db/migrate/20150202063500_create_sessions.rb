class CreateSessions < ActiveRecord::Migration
  def change
    create_table :game_session do |t|
    	t.string :gameboard
    end
  end
end
