require "delegate"
require "yaml"

#With many thanks to Dominik Bathon and Ruby Quiz

class SProc < DelegateClass(Proc)
  
  attr_reader :proc_src
  
  def initialize(proc_src)
    super(eval("Proc.new { #{proc_src} }"))
    @proc_src = proc_src
  end
  
  def ==(other)
    @proc_src == other.proc_src rescue false
  end
  
  def inspect
    "#<SProc: #{@proc_src.inspect}>"
  end
  alias :to_s :inspect
  
  
  def to_yaml(opts = {})
    YAML::quick_emit(self.object_id, opts) { |out|
      out.map("!rubyquiz.com,2005/SProc" ) { |map|
        map.add("proc_src", @proc_src)
      }
    }
  end
  
end

YAML.add_domain_type("rubyquiz.com,2005", "SProc") { |type, val|
  SProc.new(val["proc_src"])
}
