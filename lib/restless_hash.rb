# Dynamically creates a class based on a hash
# Much like our good friend actionscript3
class RestlessHash < Hash
    #Load in a user's hash if they give me one
  def initialize( hash = nil )
    hash.each do |k, v|
      self[k] = v
    end if !hash.nil?
  end

    #define id's
  def id; self[:id] || self['id']; end; def id=(v); self[:id] = v; end;

    #Define the respond to method
  def respond_to?(v)
    self.has_key?(v)
  end

    #Attempt to index this guy via the the index requested
  def method_missing( sym, *args )
    (args.size == 0)? self[sym] || self[sym.to_s]: self[sym] = args[0]
  end
end
