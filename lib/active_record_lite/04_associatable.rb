require_relative '03_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key,
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    self.class_name = options[:class_name] || name.to_s.singularize.camelize
    self.primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.foreign_key = options[:foreign_key] || "#{self_class_name.to_s.downcase.singularize}_id".to_sym
    self.class_name = options[:class_name] || name.to_s.singularize.camelize
    self.primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method(name) do
      foreign_key = self.send(options.foreign_key)
      target = options.model_class
      target.where(options.primary_key => foreign_key).first
    end
  end

  def has_many(name, options = {})
    options= HasManyOptions.new(name, self, options)

    define_method(name) do
      primary_key = self.send(options.primary_key)
      target = options.model_class
      target.where(options.foreign_key => primary_key)
    end
  end

  def assoc_options
    # Wait to implement this in Phase V. Modify `belongs_to`, too.


  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable


end
