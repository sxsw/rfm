module Rfm
	PATH = File.expand_path(File.dirname(__FILE__))
	$LOAD_PATH.unshift(PATH) unless $LOAD_PATH.include?(PATH)
end

require 'thread' # some versions of ActiveSupport will raise error about Mutex unless 'thread' is loaded.
require 'active_support'
# ActiveSupport appears to load these automatcially
	#require 'active_support/core_ext/object/blank'
	#require 'active_support/ordered_hash'
	require 'active_support/version'
require 'rfm/utilities/core_ext'
require 'rfm/utilities/case_insensitive_hash'
#require 'rfm/utilities/config'
#require 'rfm/utilities/factory'
#require 'rfm/version.rb'

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
  autoload :XmlParser,    'rfm/utilities/xml_parser'
  autoload :ComplexQuery, 'rfm/utilities/complex_query'
  autoload :Config,       'rfm/utilities/config'
  autoload :Factory,      'rfm/utilities/factory'
  autoload :VERSION,      'rfm/version'

	module Metadata
		autoload :Script,         'rfm/metadata/script'
		autoload :Field,          'rfm/metadata/field'
		autoload :FieldControl,   'rfm/metadata/field_control'
		autoload :ValueListItem,  'rfm/metadata/value_list_item'
	end

	def info
    rslt = <<-EEOOFF
      Name: ginjo-rfm
      Version: #{VERSION}
      ActiveSupport Version: #{ActiveSupport::VERSION::STRING}
      ActiveModel Loaded? #{defined?(ActiveModel) ? 'true' : 'false'}
      ActiveModel Loadable? #{begin; require 'active_model'; rescue LoadError; $!; end}
      XML Parser: #{XmlParser.backend}
    EEOOFF
    rslt.gsub!(/^[ \t]*/, '')
  rescue
  	"Could not retrieve info: #{$!}"
	end
	
	def info_short
		"Using ginjo-rfm version #{::Rfm::VERSION} with #{XmlParser.backend}"
	end
	
	def_delegators 'Rfm::Factory', :servers, :server, :db, :database, :layout, :models, :modelize
	def_delegators 'Rfm::XmlParser', :backend, :backend=
	def_delegators 'Rfm::Config', :config, :get_config, :config_clear
	
	extend self

end # Rfm
