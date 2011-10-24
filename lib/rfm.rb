path = File.expand_path(File.dirname(__FILE__))
$:.unshift(path) unless $:.include?(path)

require path + '/rfm/utilities/case_insensitive_hash'
require path + '/rfm/utilities/factory'

module Rfm

	VERSION = File.read(File.join(File.expand_path(File.dirname(File.dirname(__FILE__))), 'VERSION')) rescue "no VERSION file found"
  puts "Using wbrinsf-rfm version: #{VERSION}"
  
  class CommunicationError  < StandardError; end
  class ParameterError      < StandardError; end
  class AuthenticationError < StandardError; end

  autoload :Error,     'rfm/error'
  autoload :Server,    'rfm/server'
  autoload :Database,  'rfm/database'
  autoload :Layout,    'rfm/layout'
  autoload :Resultset, 'rfm/resultset'
  
end