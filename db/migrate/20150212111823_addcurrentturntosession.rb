class Addcurrentturntosession < ActiveRecord::Migration
  def change
    add_column :sessions, :current_player, :string
  end
end
