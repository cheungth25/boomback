class CreateEntities < ActiveRecord::Migration[5.1]
  def change
    create_table :entities do |t|
      t.integer :entity_type
      t.integer :x
      t.integer :y
      t.integer :bomb_str
      t.integer :char_id
      t.integer :game_id

      t.timestamps
    end
  end
end
