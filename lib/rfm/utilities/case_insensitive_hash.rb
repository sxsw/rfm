class SuperProxy
  def initialize(obj)
    @obj = obj
  end

  def method_missing(meth, *args, &blk)
    @obj.class.superclass.instance_method(meth).bind(@obj).call(*args, &blk)
  end
end

class Object
  private
  def sup
    SuperProxy.new(self)
  end
end

module Rfm
  class CaseInsensitiveHash < Hash
    def []=(key, value)
      super(key.to_s.downcase, value)
    end
    def [](key)
      super(key.to_s.downcase)
    end
  end
end