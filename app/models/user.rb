class User < ActiveRecord::Base
  include CacheableModule
  validates :email, presence: true, uniqueness: true
  attr_cacheable :id, :email
  has_many :bookings, dependent: :destroy
  cacheable_has_many :bookings
end
