class User < ActiveRecord::Base
  include CacheableModule
  attr_cacheable :id
  has_many :bookings, dependent: :destroy
  cacheable_has_many :bookings
end
