require "fileutils"
require "pathname"
require "dolzenko/error_print"

module Scholarly
  class CodeCollector
    class << self
      attr_accessor :root
    end

    self.root = Pathname("../../../silo").expand_path(__FILE__)
    # self.root = Pathname("/root/silo")

    def self.collect_gems!
      rubygems_codes_root = root + "rubygems"
      FileUtils.mkdir_p(rubygems_codes_root) unless File.directory?(rubygems_codes_root)

      for spec in github_specs
        begin
          gemspec = Gem::Specification.new(spec[0], spec[1].to_s)
          gem_file_path = download_gem(gemspec, rubygems_codes_root)
          GemCode.create!(:uri => gem_uri(gemspec),
                          :path => gem_file_path,
                          :clone_state => "cloned")
          puts "Downloaded #{ gem_file_path }"
        rescue Exception => e
          propagate_interrupt(e)
          puts "Failed to retrieve gem #{ spec[0] }"
          puts e.error_print
        end
      end
    end

    def self.gem_uri(gemspec)
      "http://gems.github.com/gems/#{ gemspec.name }-#{ gemspec.version }.gem"
    end

    def self.propagate_interrupt(e)
      raise if e.class.name.in?(["IRB::Abort", "Interrupt"]) # re-raise user interrupt
    end

    def self.github_specs
      for source, specs in Gem::SpecFetcher.fetcher.list
        return specs if source.host == "gems.github.com"
      end
    end

    def self.download_gem(gemspec, target_dir)
      puts "Downloading #{ gemspec }"
      fetcher = Gem::RemoteFetcher.fetcher
      fetcher.download(gemspec, "http://gems.github.com/", target_dir)
    end

    def self.collect_rails!
      rails_codes_root = root + "rails"
      FileUtils.mkdir_p(rails_codes_root) unless File.directory?(rails_codes_root)

      # update_rails_codes_from_cached_uris!
      
      RubyCode.where(:clone_state => 'not_attempted').to_a.first(600).each do |ruby_code|
        next unless ruby_code.uri.include?("github.com")

        next if ruby_code.clone_state.in?(["cloned", "failed", "disabled"])

        begin
          repo_path = CodeRepository.clone(rails_codes_root, ruby_code.uri)
          ruby_code.path = repo_path
          ruby_code.clone_state = "cloned"
          ruby_code.save
          puts "Successfully cloned #{ ruby_code.uri }"
        rescue Exception => e
          propagate_interrupt(e)
          puts Exception.error_print(e)
          ruby_code.clone_state = "failed"
          ruby_code.clone_attempts = ruby_code.clone_attempts.to_i + 1
          ruby_code.save
          puts "Failed to clone #{ ruby_code.uri } for #{ ruby_code.clone_attempts } time(s)"
        end
      end
    end

    def self.update_rails_codes_from_cached_uris!
      uris = GoogleCodeSearch.cached_repository_uris +
              GitHubCodeSearch.cached_repository_uris
      for uri in uris
        next if RailsCode.exists?(:uri => uri)
        RailsCode.create!(:uri => uri, :clone_state => "not_attempted")
      end
    end

    def self.prune_all
      RubyCode.find_each(:conditions => { :clone_state => 'cloned' }) do |ruby_code|
        next unless File.directory?(ruby_code.path)
        puts "Pruning #{ ruby_code.path }"
        CodeRepository.prune_cloned_dir(ruby_code.path)
      end
    end
  end
end