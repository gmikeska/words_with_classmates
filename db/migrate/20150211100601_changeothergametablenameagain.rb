class Changeothergametablenameagain < ActiveRecord::Migration
  def change
    rename_table :game_session, :user_sessions
  end
end
