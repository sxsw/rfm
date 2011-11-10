module Rfm
	VERSION_DEFAULT = '1.4.2.pre'
	VERSION = File.read(File.join(File.expand_path(File.dirname(File.dirname(File.dirname(__FILE__)))), 'VERSION')) rescue VERSION_DEFAULT
	# 		if File.exists?('../../VERSION')
	# 			File.read('../../VERSION')
	# 		else
	#   		'1.4.2.pre'
	# 		end
  module Version # :nodoc: all
    MAJOR, MINOR, PATCH, BUILD = VERSION.split('.')
    NUMBERS = [ MAJOR, MINOR, PATCH, BUILD ]
  end
end
