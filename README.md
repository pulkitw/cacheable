# cacheable
This is a basic app scaffolded to use CacheableModule.

CacheableModule provides two class methods 

  1. attr_cacheable(*attrs)
    This method expects attributes as arguments which are assumed to be columns on the model.
    It gives a class method cache_find_by_<attr>(val) to load object from cache.
    It also adds a after_commit hook to clear cache.

  2. cacheable_has_many(association_name)
    This method expects an association name as argument which is assumed to be a has_many type association on the model.
    It gives a instance method cached_<assocation_name> to load the association result from cache.
    It also adds after_commit hook on association and model to clear cache.

  
