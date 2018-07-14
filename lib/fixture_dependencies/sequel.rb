class << FixtureDependencies
  private
  
  def add_associated_object_S(reflection, attr, object, assoc)
    if reflection[:type] == :one_to_one
      object.send("#{reflection[:name]}=", assoc)
    else
      object.send("add_#{attr.to_s.singularize}", assoc) unless object.send(attr).include?(assoc)
    end
  end
  
  def model_find_S(model, pk)
    model[pk] || raise_model_error_S("No matching record for #{model.name}[#{pk.inspect}]")
  end
  
  def model_find_by_pk_S(model, pk)
    model[pk]
  end
  
  def model_save_S(object)
    object.db_schema.each do |(col, info)|
      type = info[:type].to_s.downcase
      next if object[col].nil?
      if Sequel.respond_to?(:pg_row) && !type.slice!('pg_row_').nil? && object[col].is_a?(Hash)
        hash = object[col].each_with_object({}) do |(k, v), memo|
          memo[k.to_sym] = v
          memo
        end
        object[col] = object.db.row_type(type.to_sym, **hash)
      elsif Sequel.respond_to?(:pg_array) && !type.chomp!('[]').nil?
        object[col] = Sequel.pg_array(object[col])
      elsif Sequel.respond_to?(:pg_json) && type == 'json'
        object[col] = Sequel.pg_json(object[col])
      elsif Sequel.respond_to?(:pg_jsonb) && type == 'jsonb'
        object[col] = Sequel.pg_jsonb(object[col])
      end
    end
    object.raise_on_save_failure = true
    object.save
  end
  
  def raise_model_error_S(message)
    raise Sequel::Error, message
  end
  
  def reflection_S(model, attr)
    model.association_reflection(attr)
  end
  
  def reflection_class_S(reflection)
    reflection.associated_class
  end
  
  def reflection_key_S(reflection)
    reflection[:key]
  end
  
  def reflection_type_S(reflection)
    reflection[:type]
  end
end
