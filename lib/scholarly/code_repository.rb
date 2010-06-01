require "fileutils"
require "dolzenko/shell_out"
require "dolzenko/error_print"
require "timeout"
require "English"

module Scholarly
  class CodeRepository
    class << self
      attr_accessor :clone_retry_count
    end
    self.clone_retry_count = 0
    
    # Clones repository with uri at path
    def self.clone(path, uri)
      raise ArgumentError, "don't know how to create Repository from #{ uri }" unless uri.include?("github")
      uri = URI.parse(uri)
      dir = "#{ File.join(path, uri.host, File.dirname(uri.path)) }"

      cloned_path = File.join(dir, File.basename(uri.path).sub(/\.git$/, ""))
      raise ArgumentError, "#{ uri } appears to be cloned already at #{ cloned_path }" if File.exist?(cloned_path)

      FileUtils.mkdir_p(dir)

      try_count = 0
      Dir.chdir(dir) do
        begin
          try_count += 1
          cmd = "git clone --quiet --depth 1 #{ uri }"
#          ShellOut.shell_out_with_system(cmd, :raise_exceptions => true, :verbose => true)
          puts "spawn(#{cmd})"
          git_pid = spawn(cmd, :chdir => dir)
          timeout = 5 * 60
          begin
            puts "Waiting for Git to exit..."
            while timeout > 0 && Process.waitpid(git_pid, Process::WNOHANG).nil? # while git finishes
              sleep(2) # probing every 2 seconds
              print "."
              timeout -= 2
              if timeout < 0
                puts "Git timed out"
                raise "Git timed out"
              end
            end
          rescue Errno::ECHILD => e
            # git finished
            raise unless e.message == "No child processes"
            puts "Swallowed Errno::ECHILD"
          end
          # $CHILD_STATUS.exitstatus is available after Process.waitpid(git_pid, Process::WNOHANG)
          raise "Git command exited with non-zero status" if $CHILD_STATUS.exitstatus != 0
        rescue Exception => e
          puts Exception.error_print(e)
          if e.is_a?(Interrupt) || try_count >= clone_retry_count
            # user interrupt or can't retry any longer
            FileUtils.rm_rf(cloned_path)
            raise
          else
            # can retry
            retry
          end
        ensure
          # kill git when interrupted
          puts "Killing Git with #{ git_pid } pid"
          Process.kill(:KILL, git_pid) rescue nil
          puts "Waiting on Git with #{ git_pid } pid"
          Process.waitpid(git_pid) rescue nil
        end
      end

      cloned_path
    end
  end
end