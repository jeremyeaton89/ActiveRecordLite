require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  
  extend Searchable
  extend Associatable
  
  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name
  end

  def self.all
    query = <<-SQL
      SELECT * 
      FROM #{table_name}
    SQL
    objects = DBConnection.execute(query)
    parse_all(objects)
  end

  def self.find(id)
    query = <<-SQL
      SELECT * 
      FROM #{table_name}
      WHERE id = ?
    SQL
    object = DBConnection.execute(query, id).first
    new(object)
  end

  def create
    value_escapes = (Array.new(self.class.attributes.count) { "?" }).join(", ")
    attribute_names = self.class.attributes.map {|attr| "'#{attr}'"}.join(", ")
    query = <<-SQL
      INSERT INTO #{self.class.table_name} (#{attribute_names})
      VALUES (#{value_escapes})
    SQL
    DBConnection.execute(query, *attribute_values)
    
    @id = self.class.all.last.id
  end

  def update
    set_attr_string = self.class.attributes.map { |attr| "#{attr} = ?"}.join(", ")

    query = <<-SQL
      UPDATE #{self.class.table_name}
      SET #{set_attr_string}
      WHERE id = #{@id}
    SQL
    DBConnection.execute(query, *attribute_values)
  end

  def save
    if @id
      update
    else
      create
    end
  end

  def attribute_values
    self.class.attributes.map do |attr|
      send(attr)
    end
  end
end