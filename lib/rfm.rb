path = File.expand_path(File.dirname(__FILE__))
$:.unshift(path) unless $:.include?(path)

require path + '/rfm/utilities/case_insensitive_hash'
require path + '/rfm/utilities/factory'
require path + '/rfm/version.rb'

module Rfm

	#VERSION = File.read(File.join(File.expand_path(File.dirname(File.dirname(__FILE__))), 'VERSION')) rescue "no VERSION file found"
	VERSION = Version::STRING
	if ENV['_'].to_s.match(/irb/)
  	puts "Using gem ginjo-rfm version: #{VERSION}"
  end
  
  class CommunicationError  < StandardError; end
  class ParameterError      < StandardError; end
  class AuthenticationError < StandardError; end

  autoload :Error,     'rfm/error'
  autoload :Server,    'rfm/server'
  autoload :Database,  'rfm/database'
  autoload :Layout,    'rfm/layout'
  autoload :Resultset, 'rfm/resultset'
  autoload :Record,    'rfm/record'
  autoload :Base,      'rfm/utilities/rfm_model'
  
	module Metadata
		autoload :Script, 'rfm/metadata/script'
		autoload :Field, 'rfm/metadata/field'
		autoload :FieldControl, 'rfm/metadata/field_control'
		autoload :ValueListItem, 'rfm/metadata/value_list_item'
	end

end