module EndlessDNS
  class Version
    VERSION = '0.1.0'
    def self.version
      puts "Version #{VERSION}"
      exit
    end
  end
end
