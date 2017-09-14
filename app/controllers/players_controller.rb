class PlayersController < ApplicationController

  def create
    @game = Game.find(params[:player][:game_id])
    @player = Player.create(name: params[:player_name], game:@game)
    render json: {player:@player, users:@game.users_info}
  end

end
