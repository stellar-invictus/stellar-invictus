class MiningWorker < ApplicationWorker
  include ApplicationHelper

  def perform(player_id, asteroid_id, is_mining = false, check_count = 0)
    player = User.ensure(player_id)
    asteroid = Asteroid.ensure(asteroid_id)

    return unless player.ship && player && asteroid

    # Get mining amount
    mining_amount = player.ship.get_mining_amount

    if !is_mining

      # Untarget npc target and is_attacking to false
      player.update(npc_target_id: nil, is_attacking: false)

      # Cancel if Player already mining this
      return if player.mining_target == asteroid

      # Untarget combat target if player is targeting mining target
      if player.target
        player.target.broadcast(:stopping_target, name: player.full_name)
        player.update(target: nil)
      end

      # Mine every 30 seconds
      player.update(mining_target: asteroid)
      player.broadcast(:refresh_target_info)

      MiningWorker.perform_in(2.second, player.id, asteroid.id, true, check_count + 2)
      return

    elsif check_count < 20

      return unless can_mine(player, asteroid, mining_amount)
      MiningWorker.perform_in(2.second, player.id, asteroid.id, true, check_count + 2)
      return

    else

      # Calculate mining_amount based on existing logic or available resources
      if asteroid.resources >= 100
        mining_amount = 1  # or whatever the standard mining_amount should be
      else
        mining_amount = 1  # you will still get 1 unit, even if fewer than 100 resources are left
      end

      # Update asteroid resources
      asteroid.update(resources: [asteroid.resources - (100 * mining_amount), 0].max)

      # Add Items to player, still respecting ship capacity
      if player.ship.get_free_weight < mining_amount
        Item::GiveToUser.(loader: "asteroid.#{asteroid.asteroid_type}_ore", amount: player.ship.get_free_weight, user: player)
      else
        Item::GiveToUser.(loader: "asteroid.#{asteroid.asteroid_type}_ore", amount: mining_amount, user: player)
      end


      # Log
      player.broadcast(:update_asteroid_resources, resources: asteroid.resources)
      player.broadcast(:refresh_player_info)

      # Tell other users who miner this rock to also update their resources
      User.where(mining_target_id: asteroid_id).is_online.each do |u|
        u.broadcast(:update_asteroid_resources_only, resources: asteroid.resources)
      end

      # Add to mission if user has active mission
      mission = player.missions.where(mission_loader: "asteroid.#{asteroid.asteroid_type}_ore", mission_status: 'active', mission_type: 'mining').where('mission_amount > 0').first
      if mission
        mission.update(mission_amount: mission.mission_amount - mining_amount)
        mission.update(mission_amount: 0) if mission.mission_amount < 0
      end

      # Log
      player.broadcast(:log, text: I18n.t('log.you_mined_from_asteroid', amount: mining_amount, ore: Item.get_attribute("asteroid.#{asteroid.asteroid_type}_ore", :name).downcase))

      # Get enemy
      EnemyWorker.perform_async(nil, player.location.id) if rand(10) == 9

      # Restart MiningWorker
      MiningWorker.perform_async(player.id, asteroid_id, true)
      return

    end
  end

  def can_mine(player, asteroid, mining_amount)
    player = player.reload
    asteroid = asteroid&.reload

    # Remove asteroid as target if depleted
    if asteroid.resources <= 0
      # Tell other users who miner this rock is depleted
      User.where(mining_target: asteroid).is_online.each do |u|
        u.broadcast(:asteroid_depleted)
        # Q: shouldn't we clear their mining targets as well?
        #    and isn't the player included in this list?
      end

      asteroid.destroy
      player.broadcast(:asteroid_depleted)
      player.update(mining_target_id: nil)
      return false
    end

    # Stop mining if user has other or no mining target
    if player.mining_target != asteroid || player.target_id != nil
      return false
    end

    # Stop mining if player's ship is full
    if player.ship.get_free_weight <= 0
      # Q: if the ship is full, is the asteroid really depleted?
      player.broadcast(:asteroid_depleted)
      player.update(mining_target_id: nil)
      return false
    end

    player.can_be_attacked
  end
end
