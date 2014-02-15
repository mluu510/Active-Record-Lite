require_relative 'db_connection'
require_relative '01_mass_object'
require 'active_support/inflector'

class MassObject
  def self.parse_all(results)
    [].tap do |arr|
      results.each do |result|
        arr << self.new(result)
      end
    end
  end
end

class SQLObject < MassObject

  attr_accessor :id

  def self.columns
    @column_names ||= begin
      # Fetch column names from DB
      query = <<-SQL
      SELECT *
      FROM #{self.table_name}
      SQL

      results = DBConnection.execute2(query)
      column_names = results.first

      # Generate getters and setters
      column_names.each do |column_name|
        define_method("#{column_name}") do
          attributes[column_name.to_sym]
        end
        define_method("#{column_name}=") do |argument|
          attributes[column_name.to_sym] = argument
        end
      end


      column_names.map(&:to_sym)
    end
  end

  def self.table_name=(table_name)
    @table_name ||= table_name
  end

  def self.table_name
    return @table_name if @table_name
    self.to_s.downcase.gsub(' ', '_').pluralize
  end

  def self.all
    query = <<-SQL
    SELECT #{table_name}.*
    FROM #{table_name}
    SQL

    results = DBConnection.execute(query)
    parse_all(results)
  end

  def self.find(id)
    query = <<-SQL
    SELECT *
    FROM #{table_name}
    WHERE id = #{id}
    SQL

    results = DBConnection.execute(query)
    parse_all(results).first
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    columns = self.attributes.keys.join(", ")
    values = self.attribute_values.map { |value| "'#{value}'" }.join(", ")
    query = <<-SQL
    INSERT INTO
      #{self.class.table_name} (#{columns})
    VALUES
      (#{values})
    SQL

    DBConnection.execute(query)
    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params={})
    columns = self.class.columns

    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}" unless columns.include?(attr_name.to_sym)
      attributes[attr_name.to_sym] = value
    end

  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end

  def update
    set_line = self.attributes.map do |attr_name, value|
      "#{attr_name} = #{value.inspect}"
    end.join(', ')
    query = <<-SQL
    UPDATE #{self.class.table_name}
    SET #{set_line}
    WHERE id = #{self.id}
    SQL

    DBConnection.execute(query)
  end

  def attribute_values
    @attributes.values
  end
end