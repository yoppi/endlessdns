##
#
# Net::DNS::RR::OPT
#

module Net
  module DNS
    class RR
      class OPT < RR
        attr_reader :name, :type, :payload, :extrcode, :version, :rdlength
        #include Net::DNS::Names
        
        class << self
          def parse_packet(data, offset)
            o = allocate
            o.send(:new_from_binary, data, offset)
          end
        end

        def new_from_binary(data, offset)
          @name, offset = dn_expand(data, offset)
          opt_rr = data.unpack("@#{offset} n n C C n n")
          @type     = opt_rr[0]
          @payload  = opt_rr[1]
          @extrcode = opt_rr[2]
          @version  = opt_rr[3] 
          @do       = (opt_rr[4] >> 15) & 0x0001
          @z        = opt_rr[4] & 0x7FFF
          @rdlength = opt_rr[5]
          offset += RRFIXEDSZ
          if (@rdlength > 0)
            offset = subclass_new_from_binary(data, offset)
          end
          build_pack
          set_type
          return [self, offset]
        end
        
        def subclass_new_from_binary(data, offset)
          # not yet 
        end

        def build_pack
          # not yet
        end

        def set_type
          @type = Net::DNS::RR::Types.new("OPT")
        end
      end
    end
  end
end
