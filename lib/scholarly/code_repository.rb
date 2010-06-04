require "fileutils"
require "dolzenko/shell_out"
require "dolzenko/error_print"
require "timeout"
require "English"

module Scholarly
  class CodeRepository
    class << self
      attr_accessor :clone_retry_count
      attr_accessor :clone_timeout_minutes
    end
    self.clone_retry_count = 0
    self.clone_timeout_minutes = 5


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
          puts "=> Executing: #{ cmd }"
          git_pid = spawn(cmd, :chdir => dir)

          wait_for_process_with_timeout(git_pid, clone_timeout_minutes)
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
          # kill git when interrupted for any reason
          terminate_process(git_pid)
        end
      end

      cloned_path
    end

    def self.terminate_process(git_pid)
      puts "\nCleaning up after Git with #{ git_pid } pid (kill -9 && wait)..."
      Process.kill(:TERM, git_pid) rescue nil
      Process.waitpid(git_pid) rescue nil
    end

    # Waits for process with `git_pid` to exit.
    # If process doesn't terminate in `timeout_minutes` - raises exception.
    # If process terminates with non-zero - raises exception.
    #
    # Tries to return process exit status.
    def self.wait_for_process_with_timeout(git_pid, timeout_minutes)
      timeout = timeout_minutes * 60
      begin
        print "Waiting for Git with pid #{ git_pid } to exit (with #{ timeout_minutes } minutes timeout)..."
        while timeout > 0 && Process.waitpid(git_pid, Process::WNOHANG).nil? # while git finishes
          sleep(2) # probing every 2 seconds
          print "."
          timeout -= 2
          if timeout <= 0
            puts "\nGit timed out"
            raise "Git timed out"
          end
        end
      rescue Errno::ECHILD => e
        # git finished
        raise unless e.message == "No child processes"
        puts "\nSwallowed Errno::ECHILD"
      end

      if $CHILD_STATUS
        # $CHILD_STATUS.exitstatus is available after Process.waitpid(git_pid, Process::WNOHANG)
        raise "Git command exited with non-zero status" if $CHILD_STATUS.exitstatus != 0
        $CHILD_STATUS.exitstatus
      else
        nil
      end
    end

    # Removes file in dir and all subdirs which don't match NOT_PRUNABLE_FILE
    # Returns true when directory is empty (removing it)
    NOT_PRUNABLE_FILE = /\.(erb|rb)$/

    def self.prune_cloned_dir(dir)
      file_emptiness = true
      dirs_emptiness = true
      files_to_delete = []

      Dir.new(dir).each do |entry|
        next if entry.in?(%w(. ..))

        entry_path = File.join(dir, entry)

        if File.directory?(entry_path)
          unless prune_cloned_dir(entry_path) # if at least one directory is not empty
            dirs_emptiness = false
          end
        else
          if entry_path =~ NOT_PRUNABLE_FILE  
            file_emptiness = false
          else
            files_to_delete << entry_path
          end
        end
      end
      
      files_to_delete.each { |e| File.delete(e) }

      dir_is_empty = file_emptiness && dirs_emptiness
      Dir.rmdir(dir) if dir_is_empty
      dir_is_empty
    end
  end
end