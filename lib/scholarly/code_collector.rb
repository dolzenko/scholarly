require "fileutils"
require "pathname"

module Scholarly
  class CodeCollector
    class << self
      attr_accessor :root
    end

    # self.root = Pathname("../../../silo").expand_path(__FILE__)
    self.root = Pathname("/root/silo")

    def self.collect_gems!
    end

    def self.collect_rails!
      rails_codes_root = root + "rails"
      FileUtils.mkdir_p(rails_codes_root) unless File.directory?(rails_codes_root)

      # update_rails_codes_from_cached_uris!
      
      RubyCode.where(:clone_state => 'not_attempted').find_each do |ruby_code|
        next unless ruby_code.uri.include?("github.com")

        next if ruby_code.clone_state.in?(["cloned", "failed", "disabled"])

        begin
          repo_path = CodeRepository.clone(rails_codes_root, ruby_code.uri)
          ruby_code.path = repo_path
          ruby_code.clone_state = "cloned"
          ruby_code.save
          puts "Successfully cloned #{ ruby_code.uri }"
        rescue Exception => e
          raise if e.class.name.in?(["IRB::Abort", "Interrupt"]) # re-raise user interrupt
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
  end
end