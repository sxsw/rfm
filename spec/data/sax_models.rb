#####  USER MODELS  #####

class FmResultset < Hash
end

class Datasource < Hash
end

class Metadata < Array
end

class Resultset < Array
  def attach_parent_objects(cursor)
    elements = cursor._parent._obj
    elements.each{|k, v| cursor.set_attr_accessor(k, v) unless k == 'resultset'}
    cursor._stack[0] = cursor
  end
end

class Record < Hash
end

class Field < Hash
  def build_record_data(cursor)
    #puts "RUNNING Field#build_field_data on record_id:#{cursor._obj['name']}"
    cursor._parent._obj.merge!(cursor._obj['name'] => (cursor._obj['data']['text'] rescue ''))
  end
end

class RelatedSet < Array
end
