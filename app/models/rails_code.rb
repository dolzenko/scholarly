class RailsCode < RubyCode
  def each_file(glob)
    unless File.directory?(path)
      puts "#{ path } registered as cloned in DB but is missing from file system"
      return
    end

    Dir[File.join(path, glob)].each do |file|
      source = IO.read(file)
      next if source.strip.empty?

      yield source, file
    end
  end
end