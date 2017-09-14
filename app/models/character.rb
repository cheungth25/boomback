class Character < ApplicationRecord
  belongs_to :player
  TILE_SIZE = 48
  PLAYER_POS = [{x:48, y:48}, {x:48, y:528}, {x:624, y:48}, {x:624, y:528}]

  def show_info
    self.reload
    return {id:self.id,
              x:self.x,
              y:self.y,
              alive:self.alive,
              player_id:self.player_id}
  end

  def self.start_pos
    PLAYER_POS
  end

  def nearestXY
    x = ((self.x % TILE_SIZE) <= TILE_SIZE/2) ? (self.x/TILE_SIZE).to_i : ((self.x/TILE_SIZE).to_i+1)
    y = ((self.y % TILE_SIZE) <= TILE_SIZE/2) ? (self.y/TILE_SIZE).to_i : ((self.y/TILE_SIZE).to_i+1)
    return {x:x, y:y}
  end
end
