class MassObject
  
  def self.set_attrs(*attributes)
    @attributes = attributes #.map(&:to_sym)
    
    attributes.each do |attribute|
      # attr_accessor attribute.to_sym
      # setter
      define_method("#{attribute}=") do |attr_value|
        instance_variable_set("@#{attribute}", attr_value)
      end
      # getter
      define_method(attribute) do
        instance_variable_get("@#{attribute}")
      end
    end
  end

  def self.attributes
    @attributes 
  end

  def self.parse_all(results)
    results.map { |result| new(result) }
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.attributes.include?(attr_name.to_sym) 
        self.send("#{attr_name}=".to_sym, value)
        # self.send()
        # instance_variable_set("@#{attr_name}", value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end
end
