class Game < ApplicationRecord
  has_many :players
  has_many :entities

  TILE_MAP = [
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 1,
    1, 0, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 0, 1,
    1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1,
    1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1,
    1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1,
    1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1,
    1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1,
    1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1,
    1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1,
    1, 0, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 0, 1,
    1, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  ]

  def only_players
    self.players.reload
    return self.players.select{|player| !player.spectator}
  end

  def owner
    return self.only_players.detect{|player| player.game_owner}
  end

  def users_info
    self.players.reload
    return self.players.map{|player|
      {id:player.id,
      name:player.name,
      ready:player.ready,
      game_id:player.game_id,
      game_owner:player.game_owner,
      spectator:player.spectator}
    }
  end

  def generate_map
    TILE_MAP.each_with_index{|tileID, index|
      if tileID != 0
        Entity.create(entity_type:tileID, x:index%15, y:(index/15).to_i, game:self)
      end
    }
    self.reload
    return self.entities.map{|entity| {
      id: entity.id,
      type: entity.entity_type,
      x: entity.x,
      y: entity.y,
      game_id: entity.game_id
      }}
  end

  def checkBombSpot(x, y)
    return (self.entities.detect{|entity| (entity.x == x && entity.y)})
  end

  def findBombs(char_id)
    return self.entities.select{|entity| (entity.char_id == char_id && entity.entity_type == 3)}
  end

  def calculateBlast(bombStrength, x, y, list)
    temp_hash = {}
    destroyList = list
    left = bombStrength
    right = bombStrength
    up = bombStrength
    down = bombStrength
    x_list = []
    y_list = []

    self.entities.each{|entity|
      if !destroyList.include?(entity.id)
        if (x==entity.x && y==entity.y) #center
          if entity.entity_type == 3
            destroyList << entity.id
          end
        elsif (y==entity.y && ((x-left) <= entity.x) && !(entity.x>x)) #left
          case entity.entity_type
          when 1
            left = x-(entity.x+1)
          when 2
            destroyList << entity.id
            left = x-entity.x
          # when 3
          #   destroyList << entity.id
          #   temp_hash = self.calculateBlast(entity.bomb_str, entity.x, entity.y, destroyList)
          #   destroyList = (destroyList + temp_hash[:destroyList]).uniq
          #   x_list = (x_list + temp_hash[:x_list]).uniq
          #   y_list = (y_list + temp_hash[:y_list]).uniq
          #   temp_hash = {}
          end
        elsif (y==entity.y && ((x+right) >= entity.x) && !(entity.x<x)) #right
          case entity.entity_type
          when 1
            right = entity.x-(x+1)
          when 2
            destroyList << entity.id
            right = entity.x-x
          # when 3
          #   destroyList << entity.id
          #   temp_hash = self.calculateBlast(entity.bomb_str, entity.x, entity.y, destroyList)
          #   destroyList = (destroyList + temp_hash[:destroyList]).uniq
          #   x_list = (x_list + temp_hash[:x_list]).uniq
          #   y_list = (y_list + temp_hash[:y_list]).uniq
          #   temp_hash = {}
          end

        elsif (x==entity.x && ((y-up) <= entity.y) && !(entity.y>y)) #up
          case entity.entity_type
          when 1
            up = y-(entity.y+1)
          when 2
            destroyList << entity.id
            up = y-entity.y
          # when 3
          #   destroyList << entity.id
          #   temp_hash = self.calculateBlast(entity.bomb_str, entity.x, entity.y, destroyList)
          #   destroyList = (destroyList + temp_hash[:destroyList]).uniq
          #   x_list = (x_list + temp_hash[:x_list]).uniq
          #   y_list = (y_list + temp_hash[:y_list]).uniq
          #   temp_hash = {}
          end

        elsif (x==entity.x && ((y+down) >= entity.y) && !(entity.y<y)) #down
          case entity.entity_type
          when 1
            down = entity.y-(y+1)
          when 2
            destroyList << entity.id
            down = entity.y-y
          # when 3
          #   destroyList << entity.id
          #   temp_hash = self.calculateBlast(entity.bomb_str, entity.x, entity.y, destroyList)
          #   destroyList = (destroyList + temp_hash[:destroyList]).uniq
          #   x_list = (x_list + temp_hash[:x_list]).uniq
          #   y_list = (y_list + temp_hash[:y_list]).uniq
          #   temp_hash = {}
          end

        end #if center, left, right, up or down
      end # recursive check for deleted entries already
    } #self.entities.each
    for i in 1..left do
      x_list << {x:x-i,y:y}
    end
    for i in 1..right do
      x_list << {x:x+i,y:y}
    end
    for i in 1..up do
      y_list << {x:x,y:y-i}
    end
    for i in 1..down do
      y_list << {x:x,y:y+i}
    end
    return {destroyList:destroyList.uniq, x_list:x_list.uniq, y_list:y_list.uniq}
  end

  def force
    self.update(started:false)
    Entity.delete_all
    Character.delete_all
    Player.all.each{|player|
      ActionCable.server.broadcast 'game_room_channel', data: {type: 'disconnect', user_id:player.id}
    }
    Player.delete_all
  end

end
