module Scholarly
  class MethodFilter < AstWalker
    def method_bodies(method_name)
      @method_name = method_name
      @method_bodies = []
      walk
      @method_bodies
    end

    def on_def(name, params, body)
      if is_ident?(name) && name[:ident] == @method_name
        @method_bodies << body
      end
    end

    def on_defs(target, period, name, params, body)
      if is_ident?(name) && name[:ident] == @method_name
        @method_bodies << body
      end
    end
  end
end