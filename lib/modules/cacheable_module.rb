module CacheableModule
  module ClassMethods
    # attr_cacheable(attr) creates cache_find_by_<attr>(val) method which caches the result of find_by_<attr>(val)
    # it added after_commit hook to clear the cache .
    # Assumption: all the arguments passed are attributes of the class that included this module and are unique keys.
    def attr_cacheable *args
      class << self
        attr_accessor :cacheable_attrs
        attr_reader :cacheable_associations
      end
      after_commit :clear_cache

      def metaclass
        class << self
          self
        end
      end

      (self.cacheable_attrs = args).each do |attr|
        metaclass.instance_eval do
          define_method "cache_find_by_#{attr}" do |arg|
            Rails.cache.fetch("#{self.name}/#{attr}/#{arg}", expires_in: 8.day) do
              Rails.logger.debug "fetching cache #{self.name}/#{attr}/#{arg}"
              self.send "find_by_#{attr}", arg
            end
          end
        end
      end
      define_method "clear_cache" do
        self.class.cacheable_attrs.each do |attr|
          val = !self.destroyed? && self.previous_changes.key?(attr) ? self.previous_changes[attr][0] : self.send(attr)
          Rails.logger.debug "deleting cache #{self.class.name}/#{attr}/#{val}"
          Rails.cache.delete("#{self.class.name}/#{attr}/#{val}")
        end
      end
    end

    # cacheable_has_many(association_name) creates a method cached_<association_name> which caches the association resultant
    # and returns it every time. It also added after_commit hook on the association class to clear the cache.
    # Assumption: association_name passed is actually an association.
    def cacheable_has_many association_name
      (@cacheable_associations ||= [])<< association_name
      define_method "cached_#{association_name}" do
        Rails.cache.fetch("#{self.class.name}/#{self.id}/#{association_name}", expires_in: 8.day) do
          Rails.logger.debug "fetching cache #{self.class.name}/#{self.id}/#{association_name}"
          self.send(association_name).to_a
        end
      end
      klass_name = self.name
      association_class_name = self.reflect_on_all_associations.find { |x| [association_name.to_s, association_name.to_sym].include? x.name }.try :class_name || association_name.to_s.classify
      association_class_name.constantize.instance_eval do
        self.send :after_commit, "clear_#{klass_name.underscore}_cache"
        define_method "clear_#{klass_name.underscore}_cache" do
          Rails.logger.debug "deleting_cache #{klass_name}/#{self.send klass_name.underscore + '_id'}/#{association_name}"
          Rails.cache.delete("#{klass_name}/#{self.send klass_name.underscore + '_id'}/#{association_name}")
        end
      end
      after_commit :clear_cached_associations

      define_method :clear_cached_associations do
        self.class.cacheable_associations.each do |a|
          Rails.logger.debug "deleting_cache #{self.class.name}/#{self.id}/#{a}"
          Rails.cache.delete("#{self.class.name}/#{self.id}/#{a}")
        end
      end

    end

  end

  def self.included(klass)
    klass.extend ClassMethods
  end

end
