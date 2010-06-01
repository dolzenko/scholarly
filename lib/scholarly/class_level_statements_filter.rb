module Scholarly
  # Here anything executable is considered Class Level Statement
  # i.e. method/class definitions are excluded
  class ClassLevelStatementsFilter
    attr_reader :statements
    
    def initialize(ast)
      @ast = ast
      @statements = []
    end

    def walk
      for statement in @ast
        if statement[0] == :module
        elsif statement[0] == :class
        elsif statement[0] == :def
        elsif statement[0] == :defs
        else
          @statements << statement
        end
      end
    end

    def on_module(*args)
      # pass
    end
    
    def on_default(type, event_args)
      @statements << [type, *event_args]
    end
  end
end