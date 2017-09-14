class Player < ApplicationRecord
  has_one :character
  belongs_to :game

  def show_info
    # self.reload
    return {id:self.id,
              name:self.name,
              ready:self.ready,
              game_id:self.game_id,
              game_owner:self.game_owner,
              spectator:self.spectator}
  end
end
