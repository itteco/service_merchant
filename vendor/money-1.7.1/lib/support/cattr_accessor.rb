# Extends the class object with class and instance accessors for class attributes,
# just like the native attr* accessors for instance attributes.
class Class # :nodoc:
  def cattr_reader(*syms)
    syms.each do |sym|
      class_eval <<-EOS
        if ! defined? @@#{sym.to_s}
          @@#{sym.to_s} = nil
        end

        def self.#{sym.to_s}
          @@#{sym}
        end

        def #{sym.to_s}
          @@#{sym}
        end

        def call_#{sym.to_s}
          case @@#{sym.to_s}
            when Symbol then send(@@#{sym})
            when Proc   then @@#{sym}.call(self)
            when String then @@#{sym}
            else nil
          end
        end
      EOS
    end
  end

  def cattr_writer(*syms)
    syms.each do |sym|
      class_eval <<-EOS
        if ! defined? @@#{sym.to_s}
          @@#{sym.to_s} = nil
        end

        def self.#{sym.to_s}=(obj)
          @@#{sym.to_s} = obj
        end

        def self.set_#{sym.to_s}(obj)
          @@#{sym.to_s} = obj
        end

        def #{sym.to_s}=(obj)
          @@#{sym} = obj
        end
      EOS
    end
  end

  def cattr_accessor(*syms)
    cattr_reader(*syms)
    cattr_writer(*syms)
  end
end
