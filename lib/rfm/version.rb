module Rfm
  VERSION_DEFAULT = 'none'
  VERSION = File.read(PATH + '/rfm/VERSION').lines.first.chomp  rescue VERSION_DEFAULT

  VERSION.instance_eval do
    def components
      VERSION.split('.')
    end

    def major
      components[0]
    end

    def minor
      components[1]
    end

    def patch
      components[2]
    end

    def build
      components[3]
    end
  end

end
