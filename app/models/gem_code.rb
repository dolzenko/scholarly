require "rubygems/format"
class GemCode < RubyCode
  def each_file(glob)
    unless File.exist?(path)
      puts "#{ path } registered as cloned in DB but is missing from file system"
      return
    end

    puts "Inflating #{ path }"
    Gem::Format.from_file_by_path(path).file_entries.each do |meta, content|
      next unless content
      
      next unless meta["path"] =~ /\.rb$/

      next if content.strip.empty?

      yield content, meta["path"]
    end
  end
end