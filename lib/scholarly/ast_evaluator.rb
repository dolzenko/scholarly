module Scholarly
  class AstEvaluator
    def self.eval(ast)
      new(ast).eval
    end

    def self.eval_statement(statement)
      new([statement]).eval[0]
    end

    def initialize(ast)
      @ast = ast
      @result = []
    end

    def eval
      for statement in @ast
        result = walk(statement)
        @result << result
      end
      @result 
    end

    def walk(statement)
      if statement[0].is_a?(Symbol) && respond_to?("on_#{ statement[0] }")
        # parser events
        send("on_#{ statement[0] }", statement[1 .. -1])
      elsif statement.is_a?(Hash) && respond_to?("on_#{ statement.keys[0] }")
        # scanner events
        send("on_#{ statement.keys[0] }", statement.values[0])
      else
        NonEvaluatable.new(statement)
      end
    end

    def on_var_ref(args)
      args = args[0]
      if args.is_a?(Hash) && args[:const]
        ConstRef.new(args[:const])
      elsif args.is_a?(Hash) && args[:kw] == "true"
        true
      elsif args.is_a?(Hash) && args[:kw] == "false"
        false
      elsif args.is_a?(Hash) && args[:kw] == "nil"
        nil
      else
        result = NonEvaluatable.new(args)
        result
      end
    end

    def on_top_const_ref(args)
      args = args[0]
      if args.is_a?(Hash) && args[:const]
        ConstRef.new("::" + args[:const])
      else
        NonEvaluatable.new(args)
      end
    end

    def on_const(token)
      ConstRef.new(token)
    end

    def on_const_path_ref(args)
      path = walk(args[0])
      target = walk(args[1])
      
      if path.is_a?(NonEvaluatable) || target.is_a?(NonEvaluatable)
        NonEvaluatable.new(args)
      else
        ConstRef.new("#{ path }::#{ target}")
      end
    end

    def on_array(statements)
      statements = statements[0]
      self.class.new(statements).eval
    end

    def on_hash(statements)
      statements = statements[0]
      if statements[0] == :assoclist_from_args
        result = {}
        for statement in statements[1]
          raise unless statement[0] == :assoc_new
          result[walk(statement[1])] = walk(statement[2])
        end
        result
      else
        NonEvaluatable.new(args)
      end
    end

    def on_bare_assoc_hash(assocs)
      result = {}
      for assoc in assocs[0]
        if assoc[0] == :assoc_new
          result[walk(assoc[1])] = walk(assoc[2])
        else
          return NonEvaluatable.new(assocs)
        end
      end
      result
    end

    def on_int(token)
      token.to_i
    end

    def on_float(token)
      token.to_f
    end

    def on_symbol_literal(args)
      args = args[0]
      if args[0] == :symbol &&
              args[1].is_a?(Hash) &&
              args[1][:ident]
        args[1][:ident].to_sym
      else
        NonEvaluatable.new(args)
      end
    end

    def on_string_literal(args)
      args = args[0]
      if args[0] == :string_content &&
              args.size == 2 &&
              args[1].is_a?(Hash) &&
              args[1][:tstring_content]
        args[1][:tstring_content]
      else
        NonEvaluatable.new(args)
      end
    end

    class ConstRef
      attr_reader :name
      
      def initialize(name)
        @name = name
      end

      def ==(other)
        name == other.name
      end
      
      def to_s
        name
      end
    end

    class NonEvaluatable
      attr_reader :ast

      def initialize(non_evaluatable_ast)
        @ast = non_evaluatable_ast
      end
    end
  end
end