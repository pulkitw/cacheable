class Booking < ActiveRecord::Base
  include CacheableModule
  attr_cacheable :id
  belongs_to :user
end
