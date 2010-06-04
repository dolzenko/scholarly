require "fileutils"
require "pathname"
require "dolzenko/error_print"

module Scholarly
  class CodeCollector
    class << self
      attr_accessor :root
    end

    self.root = Pathname("../../../silo").expand_path(__FILE__)

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

    def self.rails_codes_root
      (root + "rails").tap { |d| FileUtils.mkdir_p(d) unless File.directory?(d) }
    end

    def self.collect_rails!
      update_rails_codes_from_cached_uris! if RubyCode.count == 0

      ruby_codes_in_batches do |ruby_code|
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

    def self.ruby_codes_in_batches(&block)
      RubyCode.find_each(:conditions => { :clone_state => 'not_attempted' },
                         :batch_size => 100, &block)
    end

    def self.sample_ruby_codes(&block)
      RubyCode.where(:clone_state => 'not_attempted').to_a.first(600).each(&block)
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

    def self.ast_cache
      AstCache.new(rails_codes_root + "ast.cache")
    end

    def self.cache_parsed_asts!
      count = 0
      ast_cache.write do |writer|

        RailsCode.find_each(:conditions => { :clone_state => 'cloned' },
                            :batch_size => 10) do |ruby_code|

          next unless File.directory?(ruby_code.path)

          puts "Caching #{ ruby_code.path }"
          ruby_code.each_file("app/models/**/*.rb") do |source, env|
            next unless ast = Scholarly::Base.parse_source(source, env)
            writer.call([env[:file], ast])
          end
          count += 1
          break if count > 2
        end
      end
      nil
    end

    def self.cache_parsed_asts!
      file_count = 0
      count = 0
      ast_cache.write do |writer|

        RailsCode.find_each(:conditions => { :clone_state => 'cloned' },
                            :batch_size => 10) do |ruby_code|

          next unless File.directory?(ruby_code.path)

          puts "Caching #{ ruby_code.path }"
          ruby_code.each_file("app/models/**/*.rb") do |source, env|
            next unless ast = Scholarly::Base.parse_source(source, env)
            file_count += 1
            writer.call([env[:file], ast])
          end
          count += 1
          # break if count > 2
        end
      end
      file_count
    end

    def self.each_cached_ast
      file_count = 0
      ast_cache.each do |file, ast|
        yield file, ast
      end
      file_count
    end
  end
end