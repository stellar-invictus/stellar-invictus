class AsteroidsController < ApplicationController
  
  def mine
    if params[:id] and current_user.location.location_type == 'asteroid_field' and current_user.can_be_attacked
      asteroid = Asteroid.find(params[:id]) rescue nil
      if asteroid and asteroid.resources > 0 and asteroid.location == current_user.location
        MiningWorker.perform_async(current_user.id, asteroid.id)
        render json: {name: "#{I18n.t('overview.asteroid')} #{asteroid.asteroid_type.capitalize}", resources: asteroid.resources}, status: 200 and return
      end
    end
    render json: {}, status: 400
  end
  
end