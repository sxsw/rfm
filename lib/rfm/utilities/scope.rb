require 'rfm'
require 'rfm/base'

module Rfm
	module Scope
	
		SCOPE = Proc.new {[]}
	
		# Add scoping to Rfm::Base class methods for querying fmp records.
		# Usage: class MyModel < Rfm::Base; SCOPE = proc {|optional-scope-args| <single-or-array-of-fmp-request-hashes>}; end
		# Optionally pass :scope=>fmp-request-hash-or-array or :scope_args=>anything
		# in the FMP request options hash, to be used at scoping time
		# instead of above scope constant.
			
		def find(*args)
			new_args = apply_scope(*args)
			#Rails.logger.debug "NEW ARGS to super"
			#Rails.logger.debug new_args.to_yaml
			super(*new_args)
		end
		
		def count(*args)
			new_args = apply_scope(*args)
			#Rails.logger.debug "NEW ARGS to super"
			#Rails.logger.debug new_args.to_yaml
			super(*new_args)
		end
		
		# Mix scope requests with user requests (sorta like a cross-join of requests).
		def apply_scope(*args)
			#Rails.logger.debug "RAW ARGS"
			#Rails.logger.debug args.to_yaml
			opts = (args.size > 1 && args.last.is_a?(Hash) ? args.pop : {})
			#Rails.logger.debug "REQUESTS"
			#Rails.logger.debug args.to_yaml
			scope = [opts.delete(:scope) || self::SCOPE.call(opts.delete(:scope_args))].flatten
			return [args].flatten(1).push(opts) if !(args[0].is_a?(Array) || args[0].is_a?(Hash)) || scope.size < 1
			scoped_requests = []
			scope.each do |scope_req|
				[args].flatten.each do |req|
					scoped_requests.push(req[:omit] ? req : req.merge(scope_req))
				end
			end
			scoped_query = [scoped_requests, opts]
			#Rails.logger.debug "SCOPED QUERY"
			#Rails.logger.debug scoped_query.to_yaml
			scoped_query
		end
		
		# def self.extended(base)
		# 	puts "Extending #{base} with Scope"
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



