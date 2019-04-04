class EquipmentWorker < ApplicationWorker
  # This Worker will be run when a player uses equipment

  def perform(player)
    # Get the Player and ship
    player = User.ensure(player)

    # Set Player status to using equipment worker
    player.update_columns(equipment_worker: true)

    player_ship = player.active_spaceship

    # Target Ship
    if player.target
      target_ship = player.target.active_spaceship
      target_id = player.target.id
    elsif player.npc_target
      target_ship = player.npc_target
      target_id = player.npc_target.id
    end

    # Equipment Cycle
    while true do

      # Reload Player
      player = player.reload

      # Get Power of Player
      power = player_ship.get_power

      # Get Repair Amount of Player
      self_repair = player_ship.get_selfrepair
      remote_repair = player_ship.get_remoterepair

      # If is attacking else
      if (power > 0 || player_ship.has_active_warp_disruptor) ||
         (power > 0 && remote_repair > 0)

        # If player is targeting user -> Call Police and Broadcast
        if player.target
          call_police(player) unless (player.target.target_id == player.id) && player.target.is_attacking
          target.broadcast(:getting_attacked, name: player.full_name)
        end

        # Set Attacking to True
        player.update_columns(is_attacking: true) if !player.is_attacking

      elsif (power == 0) && (remote_repair == 0) && !player_ship.has_active_warp_disruptor && player.is_attacking

        # Set Attacking to False
        player.update_columns(is_attacking: false)

        # If player had user targeted -> stop
        if player.target
          target.broadcast(:stopping_attack, name: player.full_name)
        end

        # Shutdown if repair also 0
        shutdown(player) && (return) if (self_repair == 0) && (remote_repair == 0)

      elsif remote_repair > 0
        # If player is targeting user -> Broadcast
        if player.target
          player.target.broadcast(:getting_helped, name: player.full_name)
        end

        # Set Attacking to True
        player.update_columns(is_attacking: true) if !player.is_attacking
      end

      # If Repair -> repair
      if self_repair > 0
        if player_ship.hp < player_ship.get_max_hp

          if player_ship.hp + self_repair > player_ship.get_max_hp
            player_ship.update_columns(hp: player_ship.get_max_hp)
          else
            player_ship.update_columns(hp: player_ship.hp + self_repair)
          end

          player.broadcast(:update_health, hp: player_ship.hp)

          User.where(target_id: player_id).is_online.each do |u|
            u.broadcast(:update_target_health, hp: player_ship.hp)
          end
        else
          player.active_spaceship.deactivate_selfrepair_equipment
          self_repair = 0
          player.broadcast(:disable_equipment)
        end
      end

      # If player can attack target or remote repair
      if ((power > 0) && target_ship) || ((remote_repair > 0) && target_ship)

        if can_attack(player)

          # The attack
          attack = power
          attack = power * (1.0 - target_ship.get_defense / 100.0) if player.target

          target_ship.update_columns(hp: target_ship.reload.hp - attack.round + remote_repair)

          if player.target
            target_ship.update_columns(hp: target_ship.get_max_hp) if target_ship.hp > target_ship.get_max_hp
          end

          target_hp = target_ship.hp

          # Tell both parties to update their hp and log
          if player.target
            target.broadcast(:update_health, hp: target_hp)
            target.broadcast(:log, text: I18n.t('log.you_got_hit_hp', attacker: player.full_name, hp: attack.round))
            player.broadcast(:log,  text: I18n.t('log.you_hit_for_hp', target: player.target.full_name, hp: attack.round))
          elsif player.npc_target
            player.broadcast(:log, text: I18n.t('log.you_hit_for_hp', target: player.npc_target.name, hp: attack.round))
          end

          # Tell other users who targeted target to also update hp
          if player.target
            User.where(target_id: target_id).is_online.each do |u|
              u.broadcast(:update_target_health, hp: target_hp)
            end
            if player.target.fleet
              ChatChannel.broadcast_to(player.target.fleet.chat_room, method: 'update_hp_color', color: target_ship.get_hp_color, id: player.target.id)
            end
          elsif player.npc_target
            User.where(npc_target_id: target_id).is_online.each do |u|
              u.broadcast(:update_target_health, hp: target_hp)
            end
          end

          # If target hp is below 0 -> die
          if target_hp <= 0
            target_ship.update_columns(hp: 0)
            if player.target
              player.target.give_bounty(player)
              # Remove user from being targeted by others
              attackers = User.where(target_id: player.target.id, is_attacking: true).pluck(:id)
              player.target.remove_being_targeted
              player.target.die(false, attackers) && player.active_spaceship.deactivate_weapons
            else
              begin
                player.npc_target.give_bounty(player)
                # Remove user from being targeted by others
                player.npc_target.remove_being_targeted
                player.npc_target.drop_blueprint if player.system.wormhole? && (rand(1..100) == 100)
                player.npc_target.die if player.npc_target
                player.active_spaceship.deactivate_weapons
              rescue
                shutdown(player)
                return
              end
            end
          end

        else
          player.broadcast(:disable_equipment)
          shutdown(player)
          return
        end

      end

      # Rescue Global
      if (power == 0) &&
        (self_repair == 0) &&
        remote_repair == 0 &&
        !player_ship.has_active_warp_disruptor ||
        !player.can_be_attacked?

        player.broadcast(:disable_equipment)
        shutdown(player)
        return
      end

      # Global Cooldown
      EquipmentWorker.perform_in(2.second, player.id)
    end
  end

  # Shutdown Method
  def shutdown(player)
    player.active_spaceship.deactivate_equipment
    player.update_columns(is_attacking: false, equipment_worker: false)
  end

  # Call Police
  def call_police(player)
    player_id = player.id

    if !player.system.low? &&
      !player.system.wormhole? &&
      !Npc.police.targeting_user(player).exists? &&
      !player.target.in_same_fleet_as(player)

      if player.system.security_status == 'high'
        PoliceWorker.perform_async(player_id, 2)
      else
        PoliceWorker.perform_async(player_id, 10)
      end
    end
  end

  # Can Attack Method
  def can_attack(player)
    player = player.reload

    if player.target
      # Get Target
      target = player.target
      # Return true if both can be attacked, are in the same location and player has target locked on
      target.can_be_attacked && player.can_be_attacked && (target.location == player.location) && (player.target == target)
    elsif player.npc_target
      # Get Target
      target = player.npc_target
      # Return true if both can be attacked, are in the same location and player has target locked on
      player.can_be_attacked && (target.hp > 0) && (target.location == player.location) && (player.npc_target == target)
    else
      false
    end
  end

end
