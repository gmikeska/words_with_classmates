class Addsessiontoletterbag < ActiveRecord::Migration
  def change
    add_column :letter_bags, :session_id, :integer
  end
end
