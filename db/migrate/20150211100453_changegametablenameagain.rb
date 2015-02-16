class Changegametablenameagain < ActiveRecord::Migration
  def change
    rename_table :games, :sessions
  end
end
