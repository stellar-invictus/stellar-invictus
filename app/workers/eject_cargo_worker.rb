class EjectCargoWorker < ApplicationWorker
  # This worker will be run when the user ejects cargo
  def perform(user, loader, amount)
    user = User.ensure(user)

    item = Item.find_by(loader: loader, spaceship: user.active_spaceship, equipped: false, active: false)
    if item && amount
      structure = Structure.create(structure_type: 'container', location: user.location, user: user)

      if amount == item.count
        item.update_columns(structure_id: structure.id, user_id: nil, spaceship_id: nil, equipped: false)
      else
        item.update_columns(count: item.count - amount)
        Item.create(structure: structure, loader: item.loader, count: amount)
      end

      # Tell everyone at location to refresh players and log the eject
      user.location.broadcast(:player_appeared)
      user.location.broadcast(:log, text: I18n.t('log.user_ejected_cargo', user: user.full_name))

      # Tell user to update player info
      user.broadcast(:refresh_player_info)
    end
  end
end
