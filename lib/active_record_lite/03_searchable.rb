require_relative 'db_connection'
require_relative '02_sql_object'

module Searchable
  def where(params)
    where_line = params.map do |attr_name, value|
      "#{attr_name} = #{value.inspect}"
    end.join(' AND ')

    query = <<-SQL
    SELECT *
    FROM #{self.table_name}
    WHERE #{where_line}
    SQL

    self.parse_all(DBConnection.execute(query))
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
