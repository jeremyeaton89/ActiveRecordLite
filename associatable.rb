require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  
  attr_accessor :name, :other_class_name, :primary_key, :foreign_key
  
  def initialize(name, params)    
    @name = name
    @other_class_name = params[:class_name] || name.to_s.camelize
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || "#{name}_id".to_sym
  end

  def type
    :belongs_to
  end
end

class HasManyAssocParams < AssocParams
  
  attr_accessor :name, :self_class, :primary_key, :foreign_key
  
  def initialize(name, params, self_class)
    @other_class_name = params[:class_name] || name.to_s.singularize.camelize
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || "#{self_class.name.underscore}_id".to_sym
  end

  def type
    :has_many
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})
    
    bts = BelongsToAssocParams.new(name, params)
        
    define_method(name) do
      query = <<-SQL
        SELECT * 
        FROM #{bts.other_table}
        WHERE #{bts.primary_key} = ?
      SQL
      
      object = DBConnection.execute(query, send(bts.foreign_key)).first
      bts.other_class.new(object)
    end

  end

  def has_many(name, params = {})
    
    hm = HasManyAssocParams.new(name, params, self.class)
    
    p "SELF CLASS #{hm.self_class}"
    
    define_method(name) do
      query = <<-SQL
        SELECT * 
        FROM #{hm.other_table} 
        WHERE #{hm.foreign_key} = ?
      SQL
      
      objects = DBConnection.execute(query, send(hm.primary_key)) 
      hm.other_class.parse_all(objects)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      params1 = self.class.assoc_params[assoc1]
      params2 = params1.other_class.assoc_params[assoc2]

      if (params1.type == :belongs_to) && (params2.type == :belongs_to)
        pk1 = self.send(params1.foreign_key)
        results = DBConnection.execute(<<-SQL, pk1)
          SELECT *
            FROM #{params1.other_table}
            JOIN #{params2.other_table}
              ON #{params1.other_table}.#{params2.foreign_key}
                   = #{params2.other_table}.#{params2.primary_key}
           WHERE #{params1.other_table}.#{params1.primary_key}
                   = ?
        SQL

        params2.other_class.parse_all(results).first
      end
    end
  end
end
