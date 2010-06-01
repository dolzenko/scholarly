require "scholarly/ast_evaluator"

module Scholarly
  class DescendantFilter
    def initialize(ast)
      @ast = ast
    end

    def descendants_of(base_name)
      descendants = []
      for statement in @ast
        if statement[0] == :class && statement[2]
          base = AstEvaluator.eval_statement(statement[2])
          if base.is_a?(AstEvaluator::ConstRef)
            if base.name == base_name
              descendants << statement
            end
          end
        end
      end
      descendants
    end
  end
end