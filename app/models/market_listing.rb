# == Schema Information
#
# Table name: market_listings
#
#  id           :bigint(8)        not null, primary key
#  amount       :integer
#  listing_type :integer
#  loader       :string
#  order_type   :integer          default("sell")
#  price        :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  location_id  :bigint(8)
#  user_id      :bigint(8)
#
# Indexes
#
#  index_market_listings_on_location_id  (location_id)
#  index_market_listings_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (user_id => users.id)
#

class MarketListing < ApplicationRecord
  belongs_to :location
  belongs_to :user, optional: true

  enum listing_type: [:item, :ship]
  enum order_type: [:sell, :buy]

  def name
    result = loader
    result = Item.get_attribute(loader) if self.item?
    result
  end
end
