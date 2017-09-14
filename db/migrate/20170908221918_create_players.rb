class CreatePlayers < ActiveRecord::Migration[5.1]
  def change
    create_table :players do |t|
      t.text :name
      t.boolean :ready, :default => false
      t.boolean :game_owner, :default => false
      t.integer :game_id
      t.boolean :spectator, :default => true

      t.timestamps
    end
  end
end
