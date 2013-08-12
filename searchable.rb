require_relative './db_connection'

module Searchable
  def where(params)    
    where_string = params.map { |attr, val| "#{attr} = '#{val}'"}.join(" AND ")
    
    query = <<-SQL
      SELECT * 
      FROM #{table_name}
      WHERE #{where_string}
    SQL
    rows = DBConnection.execute(query)
    parse_all(rows)
  end
end