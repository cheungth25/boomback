class GameRoomChannel < ApplicationCable::Channel
  def subscribed
    #stream_from "game_room_channel_#{room.id}"
    stream_from "game_room_channel"
    ActionCable.server.broadcast 'game_room_channel', data: {type: 'connect', spectator:Player.find(params['player_id']).show_info}
  end

  def unsubscribed
    @player = Player.find(params['player_id'])
    @player.character.destroy if @player.character
    @player.destroy
    @game = Game.find(params['game_id'])
    if @game.players.length == 0
      @game.update(started: false)
      @game.entities.destroy_all
    end
    # set new game owner?
    ActionCable.server.broadcast 'game_room_channel', data: {type: 'disconnect', user_id:params['player_id']}
  end

  def update_entity(data)
    ActionCable.server.broadcast 'game_room_channel', data: data['data']
  end

  # spectator <--> player
  def join_game(data)
    if (@player = Player.find(params['player_id']))
      @game = Game.find(params['game_id'])
      if @game.only_players.length == 0
        @player.update(game_owner: true, spectator: false)
        ActionCable.server.broadcast 'game_room_channel', data: {type: 'add_player', users_info: @game.users_info}
      elsif ((@game.only_players.length > 0) && (@game.only_players.length < 2))
        @player.update(spectator: false)
        @game.only_players.first.update(game_owner: true) if !@game.owner
        ActionCable.server.broadcast 'game_room_channel', data: {type: 'add_player', users_info: @game.users_info}
      end #player is allowed to join game
    end #find player
  end #join_game

  def player_ready(data)
    if (@player = Player.find(params['player_id']))
      if (!@player.spectator)
        @player.update(ready: !@player.ready)
        ActionCable.server.broadcast 'game_room_channel', data: {type: 'player_ready', player: @player.show_info}
      end
    end
  end

  def game_start(data)
    @game = Game.find(params['game_id'])
    @players = @game.only_players
    @characters = []
    if (@players.all?{|player| player.ready} && !@game.started)
      @game.update(started: true)
      @players.each_with_index{|player, index|
        @characters << Character.create(x:Character.start_pos[index][:x], y:Character.start_pos[index][:y], player:player)
      }
      @entities = @game.generate_map
      ActionCable.server.broadcast 'game_room_channel', data: {type: 'game_start', game_started:@game.started, characters:@characters.map{|character| character.show_info}, entities:@entities}
    end
  end

  # def game_over(data)
  #   # wipe entities, players, characters
  #   @game.update(started: false)
  # end

  def player_action(data)
    if @player = Player.find(params['player_id'])
      if data['action_type'] == 'bomb'
        @game = Game.find(params['game_id'])
        if (@game.checkBombSpot(data['x'], data['y']) && @game.findBombs(@player.character.id).length < data['bombNum'] )
          @entity = Entity.create(entity_type:3, x:data['x'], y:data['y'], bomb_str:data['bombStrength'], char_id:@player.character.id, game:@game)
          ActionCable.server.broadcast 'game_room_channel', data: {type: 'drop_bomb', entity: {id:@entity.id, type:@entity.entity_type, x:@entity.x, y:@entity.y, game_id:@game.id}, char_id: @entity.char_id, created_at:@entity.created_at}
        end
      else
        @player.character.update(x:data['x'], y:data['y'])
        ActionCable.server.broadcast 'game_room_channel', data: {type: 'player_action', player_id: @player.id, character_id:@player.character.id, x:data['x'], y:data['y'], crop: data['crop']}
      end
    end
  end

  def bomb_blast(data)
    @game = Game.find(params['game_id'])
    if @bomb = Entity.find(data['entity']['id'])
      @game_hash = @game.calculateBlast(data['bombStrength'], data['entity']['x'], data['entity']['y'], [])
      death_zones = {center:[],x:@game_hash[:x_list],y:@game_hash[:y_list]}
      @game_hash[:destroyList].each{ |id|
        entity = Entity.find(id)
        if (entity.entity_type == 3)
          death_zones[:center] << {x:entity.x, y:entity.y}
        end
        entity.destroy
      }
      killChars = []
      @game.only_players.each{|player|
        player_hash = player.character.nearestXY
        if (death_zones[:center].include?(player_hash) || death_zones[:x].include?(player_hash) || death_zones[:y].include?(player_hash))
          killChars << player.character.id
          player.character.update(alive:false)
        end
      }
      #return characters??
      ActionCable.server.broadcast 'game_room_channel', data: {type: 'bomb_triggered', destroyList: @game_hash[:destroyList], death_zones:death_zones, killChars:killChars}
    end
  end

  def exit(data)
    @player = Player.find(params['player_id'])
    @player.character.destroy if @player.character
    @player.destroy
    ActionCable.server.broadcast 'game_room_channel', data: {type: 'disconnect', user_id:params['player_id']}
  end

end
