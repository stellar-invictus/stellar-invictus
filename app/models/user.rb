# == Schema Information
#
# Table name: users
#
#  id                     :bigint(8)        not null, primary key
#  admin                  :boolean
#  avatar                 :string
#  banned                 :boolean
#  banned_until           :datetime
#  banreason              :string
#  bio                    :text
#  bounty                 :integer          default(0)
#  bounty_claimed         :integer          default(0)
#  chat_mod               :boolean          default(FALSE)
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  corporation_role       :integer          default("recruit")
#  docked                 :boolean          default(FALSE)
#  donator                :boolean          default(FALSE)
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  equipment_worker       :boolean          default(FALSE)
#  family_name            :string
#  full_name              :string
#  in_warp                :boolean          default(FALSE)
#  is_attacking           :boolean
#  last_action            :datetime
#  logout_timer           :boolean          default(FALSE)
#  muted                  :boolean          default(FALSE)
#  name                   :string
#  online                 :integer          default(0)
#  provider               :string
#  remember_created_at    :datetime
#  reputation_1           :float            default(0.0)
#  reputation_2           :float            default(0.0)
#  reputation_3           :float            default(0.0)
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  route                  :string           default([]), is an Array
#  uid                    :string
#  units                  :integer          default(10)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  active_spaceship_id    :integer
#  corporation_id         :bigint(8)
#  faction_id             :bigint(8)
#  fleet_id               :bigint(8)
#  location_id            :bigint(8)
#  mining_target_id       :integer
#  npc_target_id          :integer
#  system_id              :bigint(8)
#  target_id              :integer
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_corporation_id        (corporation_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_faction_id            (faction_id)
#  index_users_on_family_name_and_name  (family_name,name) UNIQUE
#  index_users_on_fleet_id              (fleet_id)
#  index_users_on_location_id           (location_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_system_id             (system_id)
#
# Foreign Keys
#
#  fk_rails_...  (corporation_id => corporations.id)
#  fk_rails_...  (faction_id => factions.id)
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (system_id => systems.id)
#

class User < ApplicationRecord
  include CanBroadcast

  acts_as_voter

  ## -- RELATIONSHIPS
  belongs_to :faction, optional: true
  belongs_to :system, optional: true
  belongs_to :location, optional: true
  belongs_to :fleet, optional: true
  belongs_to :corporation, optional: true

  belongs_to :target, class_name: User.name, foreign_key: :target_id, optional: true
  belongs_to :active_spaceship, class_name: Spaceship.name, foreign_key: :active_spaceship_id, optional: true
  belongs_to :mining_target, class_name: Asteroid.name, foreign_key: :mining_target_id, optional: true
  belongs_to :npc_target, class_name: Npc.name, foreign_key: :npc_target_id, optional: true

  has_many :chat_messages, dependent: :destroy
  has_many :spaceships, dependent: :destroy
  has_many :items, dependent: :destroy
  has_many :structures, dependent: :destroy
  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships
  has_many :craft_jobs, dependent: :delete_all
  has_many :missions, dependent: :destroy
  has_many :blueprints, dependent: :destroy
  has_many :market_listings, dependent: :destroy

  has_and_belongs_to_many :chat_rooms

  ## -- ATTRIBUTES
  alias_attribute :ship, :active_spaceship

  enum corporation_role: [:recruit, :lieutenant, :commodore, :admiral, :founder]

  ## -- VALIDATIONS
  validates :name,
    presence: true,
    uniqueness: { scope: :family_name },
    format: { with: /\A[a-zA-Z]+\z/i, message: I18n.t('validations.can_only_contain_letters') },
    length: { minimum: 2, maximum: 20, too_short: I18n.t('validations.too_short_2'), too_long: I18n.t('validations.too_long_name') }
  validates :family_name,
    presence: true,
    format: { with: /\A[a-zA-Z]+\z/i, message: I18n.t('validations.can_only_contain_letters') },
    length: { minimum: 2, maximum: 20, too_short: I18n.t('validations.too_short_2'), too_long: I18n.t('validations.too_long_name') }
  validates :avatar, presence: true
  validates :email, presence: true, uniqueness: true

  validate :check_avatar, on: :create

  # Devise
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: %i[facebook]

  ## -- SCOPES
  scope :targeting_user, ->(user) { where(target: user) }
  scope :is_online, -> { where('users.online > 0') }
  scope :in_name_order, -> { order(:family_name, :name) }
  scope :in_space, -> { where(docked: false) }

  serialize :route, Array

  ## -- CALLBACKS
  # Sets full name after create
  before_save do
    self.full_name = "#{name} #{family_name}".downcase.titleize
  end

  before_destroy do
    self.corporation.destroy if self.founder? && self.corporation # corporation
    Friendship.where(friend_id: self.id).destroy_all # friendships
    GameMail.where(sender_id: self.id).destroy_all # game mails
  end

  ## — CLASS METHODS
  # Overridden from Devise to eager_load(:system, :active_spaceship)
  def self.serialize_from_session(key, salt)
    record = where(id: key).eager_load(:system, :active_spaceship).first
    record if record && record.authenticatable_salt == salt
  end

  ## — INSTANCE METHODS
  # Verify Avatar
  VALID_AVATARS = %w[
    M_1 M_2 M_3 M_4 M_5 M_6 M_7 M_8 M_9 M_10 M_11 M_12 M_13 M_14 M_15 M_16 M_17
    F_1 F_2 F_3 F_4 F_5 F_6 F_7 F_8 F_9 F_10 F_11 F_12 F_13 F_14 F_15
  ].freeze
  def check_avatar
    unless VALID_AVATARS.include?(self.avatar)
      errors.add(:avatar, 'has not a correct value')
    end
  end

  def channel_id
    "player_#{self.id}"
  end

  def location=(value)
    # The user's system should always be the same as the system of their current Location
    super(value)
    self.system = value.system if value
    value
  end

  # Will be called when a user loggs in
  def appear
    AppearWorker.perform_async(self.id)
  end

  # Will be called when a user loggs off
  def disappear
    self.update(target: nil) && DisappearWorker.perform_async(self.id)
  end

  def is_online?
    self.online > 0
  end

  def ship_is_functional?
    !self.active_spaceship&.hp.to_i.zero?
  end

  # Returns if player can be attacked
  def can_be_attacked
    !docked? && !in_warp? && is_online? && ship_is_functional?
  end
  alias can_be_attacked? can_be_attacked

  # Lets the player die
  def die(police = false, attackers = nil)
    old_system = self.system

    loot = self.active_spaceship.drop_loot if self.active_spaceship

    # Run Killmail Worker
    hash = { id: self.id, full_name: self.full_name, avatar: self.avatar, ship_name: self.active_spaceship.name,
             bounty: self.bounty, system_name: old_system.name, site_name: self.location.get_name }
    hash.reverse_merge!(corporation: { id: self.corporation.id, name: self.corporation.name, ticker: self.corporation.ticker }) if self.corporation
    KillmailWorker.perform_async(hash, attackers, loot)

    # Tell others in system that player "warped out"
    self.location.broadcast(:player_warp_out, name: self.full_name)
    self.location.broadcast(:log, text: I18n.t('log.got_killed', name: self.full_name))

    # Create Wreck and fill with random loot
    self.active_spaceship.deactivate_equipment
    self.location.broadcast(:player_appeared)

    # Destroy current spaceship of user and give him a nano if not insured
    old_ship = self.active_spaceship&.destroy
    if old_ship&.insured && !police
      spaceship = user.spaceships.create(name: old_ship.name, hp: Spaceship.get_attribute(old_ship.name, :hp))
      self.update(active_spaceship: spaceship)
    else
      self.give_nano
    end

    # Make User docked at his factions station
    rand_location = self.faction.locations.station.random_row
    self.update(
      in_warp: false,
      docked: true,
      location: rand_location,
      target_id: nil,
      mining_target_id: nil,
      npc_target_id: nil
    )

    # Tell user to reload page
    self.broadcast(:reload_page)

    # Tell everyone in new system to update their local players
    old_system.update_local_players

    PlayerDiedWorker.perform_in(1.second, self.id)
  end

  # Returns if user is in same fleet with given id
  def in_same_fleet_as(other_user)
    self.fleet_id && self.fleet_id == other_user.fleet_id
  end

  # Returns if user is in same fleet with given id
  def in_same_corporation_as(other_user)
    self.corporation_id && self.corporation_id == other_user.corporation_id
  end

  # Gets the user remove being a target of other players
  def remove_being_targeted
    Npc.targeting_user(self).update_all(target_id: nil)
    User.targeting_user(self).each do |user|
      user.update(target: nil)
      user.active_spaceship.deactivate_equipment if user.is_attacking?
      user.broadcast(:remove_target)
    end
  end

  # Docks the player
  def dock
    self.update(docked: true, target: nil)
    self.location.broadcast(:player_warp_out, name: self.full_name)
    remove_being_targeted
  end

  # Undocks the player
  def undock
    if self.docked
      self.update(docked: false)
      self.location.broadcast(:player_appeared)
    end
  end

  # Returns if player can buy a ship
  def can_buy_ship(name)
    ship_vars = Spaceship.get_attribute(name)
    ship_vars && (self.units >= ship_vars['price']) && self.location.get_ships_for_sale.has_key?(name)
  end

  # Reduce the user's units
  def reduce_units(amount)
    self.decrement!(:units, amount)
  end

  # Give the user units
  def give_units(amount)
    if self.corporation && (self.corporation.tax > 0)
      corp_tax = amount * (self.corporation.tax / 100)
      new_amount = amount - corp_tax
      ActiveRecord::Base.transaction do
        self.corporation.increment!(:units, corp_tax)
        self.increment!(:units, new_amount)
      end
    else
      self.increment!(:units, amount)
    end
  end

  # Give user a nano
  # { loader => equipped }
  STARTING_EQUIPMENT = {
    'equipment.miner.basic_miner' => true,
    'equipment.weapons.laser_gatling' => true
  }.freeze
  def give_nano
    self.active_spaceship = Spaceship.build_for_user(
      self,
      ship: 'Nano',
      hp: 150,
      starting_equipment: STARTING_EQUIPMENT
    )
    self.save
  end

  # Give bounty to player (50% share of loss)
  def give_bounty(player)
    if self.bounty > 0
      value = (self.active_spaceship.get_total_value * 0.5).round

      if value <= self.bounty
        self.decrement!(:bounty, value)
      else
        value = self.bounty
        self.update(bounty: 0)
      end

      player.increment!(:bounty_claimed, value)
      player.give_units(value)

      player.broadcast(:notify_alert, text: I18n.t('notification.received_bounty', user: self.full_name, amount: value))
      player.broadcast(:refresh_player_info)
    end
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.skip_confirmation!
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session['devise.facebook_data'] && session['devise.facebook_data']['extra']['raw_info']
        user.email = data['email'] if user.email.blank?
        user.password = Devise.friendly_token[0, 20]
        user.uid = session['devise.facebook_data']['uid']
        user.provider = session['devise.facebook_data']['provider']
        user.skip_confirmation!
      end
    end
  end

  # Teleports to another user
  def teleport(user)
    self.location.broadcast(:player_warp_out, name: full_name)
    old_system = self.system
    self.update(location: user.location, docked: user.docked, in_warp: false)
    # Tell everyone in old system to update their local players
    old_system.update_local_players
    # Tell everyone in new system to update their local players
    self.reload.system.update_local_players
    self.location.broadcast(:player_appeared)
    self.broadcast(:warp_finish)
  end

  def ban(duration_in_hours, reason)
    duration_in_hours = duration_in_hours.to_i

    self.banned = true
    self.banreason = reason
    # Q: Are these times in UTC?
    self.banned_until = (duration_in_hours == 0) ? nil : (Time.now.utc + duration_in_hours.hours)
    self.save
    self.broadcast(:reload_page)
  end

  def unban
    self.update(banned: false, banned_until: nil, banreason: nil)
  end

  def has_blueprints_for?(loader)
    self.blueprints.where(loader: loader).exists?
  end

  def give_blueprints_for(loader, efficiency: 1.5)
    blueprint = Blueprint.where(user: self, loader: loader).first_or_initialize
    blueprint.efficiency = efficiency
    blueprint.save!
  end

end
