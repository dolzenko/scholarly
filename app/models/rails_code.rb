class RailsCode < RubyCode
  def each_file(glob)
    return unless path
    
    unless File.directory?(path)
      puts "#{ path } registered as cloned in DB but is missing from file system"
      return
    end

    Dir[File.join(path, glob)].each do |file|
      source = IO.read(file)
      next if source.strip.empty?

      env = { :file => file }
      yield source, env
    end
  end
end