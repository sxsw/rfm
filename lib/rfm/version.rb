module Rfm

	VERSION_DEFAULT = 'none'
	VERSION = File.read(PATH + '/rfm/VERSION').first.gsub(/\n|\r/,'')  rescue VERSION_DEFAULT #File.read(File.join(File.expand_path(File.dirname(File.dirname(File.dirname(__FILE__)))), 'VERSION')) rescue VERSION_DEFAULT
  
  VERSION.instance_eval do
  	def components; VERSION.split('.'); end
  	def major; components[0]; end
  	def minor; components[1]; end
  	def patch; components[2]; end
  	def build; components[3]; end
  end
end
