module CanBroadcast
  extend ActiveSupport::Concern

  def broadcast(method, **kwargs)
    ActionCable.server.broadcast(self.channel_id, { method: method, **kwargs })
  end

  def channel_id
    raise 'Subclasses should override this method to generate their own type of channel_id'
  end
end
