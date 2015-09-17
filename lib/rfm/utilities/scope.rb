require 'rfm'
require 'rfm/base'

module Rfm
  module Scope

    SCOPE = Proc.new {[]}

    # Add scoping to Rfm::Base class methods for querying fmp records.
    # Usage:
    #   class MyModel < Rfm::Base
    #     SCOPE = proc { |optional-scope-args| <single-or-array-of-fmp-request-hashes> }
    #   end
    #
    # Optionally pass :scope=>fmp-request-hash-or-array or :scope_args=>anything
    # in the FMP request options hash, to be used at scoping time,
    # instead of above scope constant.

    def find(*args)
      new_args = apply_scope(args)
      super(*new_args)
    end

    def count(*args)
      new_args = apply_scope(args)
      super(*new_args)
    end

    # Mix scope requests with user requests with a constraining AND logic.
    # Also handles request options.
    def apply_scope(args, input_scope=nil)
      #puts "APPLY_SCOPE args:#{args} input_scope:#{input_scope}"
      opts = (args.size > 1 && args.last.is_a?(Hash) ? args.pop : {})
      scope_args = opts.delete(:scope_args) || self
      raw_scope = input_scope || opts.delete(:scope) || self::SCOPE
      scope = [raw_scope.is_a?(Proc) ? raw_scope.call(scope_args) : raw_scope].flatten.compact
      #puts "APPLY_SCOPE scope:#{scope}"
      
      return [args].flatten(1).push(opts) if !(args[0].is_a?(Array) || args[0].is_a?(Hash)) || scope.size < 1
      scoped_requests = []
      scope_omits = []
      scope.each do |scope_req|
        if scope_req[:omit]
          scope_omits.push scope_req
          next
        end
        [args].flatten.each do |req|
          scoped_requests.push(req[:omit] ? req : req.merge(scope_req))
        end
      end
      scoped_requests = [args].flatten if scoped_requests.empty? 
      scoped_query = [scoped_requests | scope_omits, opts]
      #puts "APPLY SCOPE output:#{scoped_query}"
      scoped_query
    end

    # def self.extended(base)
    #   puts "Extending #{base} with Scope"
    # end

  end # Scope


  class Base
    SCOPE = Scope::SCOPE

    class << self
      # When Rfm::Base is inherited, the inheritor will extend this Scope module
      alias_method :inherited_orig, :inherited
      def inherited(model)
        super(model)
        model.send :extend, Scope
      end
    end
  end

end # Rfm
