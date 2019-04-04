class TargetNpcWorker < ApplicationWorker
  # This worker will be run whenever a player targets an npc
  def perform(player, target, round = 0, max_rounds = 0)
    target = Npc.ensure(target)
    return unless target
    player = User.ensure(player)

    if max_rounds == 0
      # Untarget old target if player is targeting new target
      if player.target_id != nil
        player.target.broadcast(:stopping_target, name: player.full_name)
        player.update(target: nil)
      end

      # Remove mining target and npc target
      player.update(mining_target: nil, npc_target: nil)

      # Get max rounds
      max_rounds = player.active_spaceship.get_target_time

      TargetNpcWorker.perform_in(1.second, player_id, target_id, round + 1, max_rounds) && (return)

    # Look every second if player docked or warped to stop targeting counter
    elsif round < max_rounds
      return if !player.can_be_attacked? ||
         (player.location != target.location) ||
         (target.hp.zero?) ||
         (player.mining_target_id != nil) ||
         (player.target_id != nil) ||
         (player.npc_target_id != nil)

      TargetNpcWorker.perform_in(1.second, player_id, target_id, round + 1, max_rounds) && (return)
    else
      # Target npc
      player.update(npc_target: target)
      player.broadcast(:refresh_target_info)
    end
  end
end
