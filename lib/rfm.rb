module Rfm
	PATH = File.expand_path(File.dirname(__FILE__))
	$LOAD_PATH.unshift(PATH) unless $LOAD_PATH.include?(PATH)
end

#require 'thread' # some versions of ActiveSupport will raise error about Mutex unless 'thread' is loaded.

require 'rfm/utilities/core_ext'
require 'rfm/utilities/case_insensitive_hash'

module Rfm
  
  class CommunicationError  < StandardError; end
  class ParameterError      < StandardError; end
  class AuthenticationError < StandardError; end

  autoload :Error,        'rfm/error'
  autoload :Server,       'rfm/server'
  autoload :Database,     'rfm/database'
  autoload :Layout,       'rfm/layout'
  autoload :Resultset,    'rfm/resultset'
  autoload :Record,       'rfm/record'
  autoload :Base,         'rfm/base'
  autoload :SaxParser,    'rfm/utilities/sax_parser'
  autoload :Config,       'rfm/utilities/config'
  autoload :Factory,      'rfm/utilities/factory'
  autoload :CompoundQuery,'rfm/utilities/compound_query'
  autoload :VERSION,      'rfm/version'
	# autoload :Fmresultset,	'rfm/utilities/fmresultset.rb'
	# autoload :Fmpxmlresult,	'rfm/utilities/fmpxmlresult.rb'
	# autoload :Fmpdsoresult,	'rfm/utilities/fmpdsoresult.rb'
	# autoload :Fmpxmllayout,	'rfm/utilities/fmpxmllayout.rb'
  autoload :Connection,   'rfm/utilities/connection.rb'

	module Metadata
		autoload :Script,         'rfm/metadata/script'
		autoload :Field,          'rfm/metadata/field'
		autoload :FieldControl,   'rfm/metadata/field_control'
		autoload :ValueListItem,  'rfm/metadata/value_list_item'
		autoload :Datum,  				'rfm/metadata/datum'
	end

	def info
    rslt = <<-EEOOFF
      Name: ginjo-rfm
      Version: #{VERSION}
      ActiveModel loadable? #{begin; Gem::Specification::find_all_by_name('activemodel')[0].version.to_s; rescue LoadError; $!; end}
      ActiveModel loaded? #{defined?(ActiveModel) ? 'true' : 'false'}
      XML-parser: #{SaxParser::Handler.get_backend}
    EEOOFF
    rslt.gsub!(/^[ \t]*/, '')
  rescue
  	"Could not retrieve info: #{$!}"
	end
	
	def info_short
		"Using ginjo-rfm version #{::Rfm::VERSION} with #{SaxParser::Handler.get_backend}"
	end
	
	def_delegators 'Rfm::Factory', :servers, :server, :db, :database, :layout
	def_delegators 'Rfm::SaxParser', :backend, :backend=
	def_delegators 'Rfm::SaxParser::Handler', :get_backend
	def_delegators 'Rfm::Config', :config, :get_config, :config_clear
	def_delegators 'Rfm::Resultset', :load_data
	
	def models(*args)
		Rfm::Base
		Rfm::Factory.models(*args)
	end
	
	def modelize(*args)
		Rfm::Base
		Rfm::Factory.modelize(*args)
	end
	
	extend self

end # Rfm
