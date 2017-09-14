class CreateCharacters < ActiveRecord::Migration[5.1]
  def change
    create_table :characters do |t|
      t.integer :x
      t.integer :y
      t.boolean :alive, :default => true
      t.integer :player_id

      t.timestamps
    end
  end
end
