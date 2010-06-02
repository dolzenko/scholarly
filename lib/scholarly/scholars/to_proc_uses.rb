module Scholarly::Scholars
  class ToProcUses < Scholarly::Base
    self.code_class = "GemCode"
    self.studies_whole_ast = true

    attr_accessor :to_proc_uses

    def initialize(*args)
      super
      @method_bodies = []
      @to_proc_uses = []
    end

    def study(ast, env)
      self.files_count += 1
      begin
        bodies = Scholarly::MethodFilter.new(ast).method_bodies("to_proc")
      rescue Exception => e
        puts e.error_print
        return
      end
      for body in bodies
        unless @method_bodies.include?(body)
          @method_bodies << body
          @to_proc_uses << { :file => env[:file] }
        end
      end
      
      self_test(ast, bodies, env)
    end

    def self_test(ast, bodies, env)
      if (grep_count = ast.inspect.scan(/\bto_proc\b/).size) != bodies.size
        puts "#{self.class.name} self test failed for #{ env }: #{ grep_count } found with grep, #{ bodies.size } with parser"
      end
    end
  end
end