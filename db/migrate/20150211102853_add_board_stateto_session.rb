class AddBoardStatetoSession < ActiveRecord::Migration
  def change
    add_column :sessions, :board_state, :text
  end
end
