class Chagegmaeidtosessionid < ActiveRecord::Migration
  def change
    rename_column :user_sessions, :game_id, :session_id
  end
end
