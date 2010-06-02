require "reflexive/variables_scope"

module Scholarly
  class AstWalker
    def initialize(ast)
      @events_tree = ast
    end

    def walk(event = @events_tree)
      type, *args = event
      if respond_to?("on_#{ type }")
        send("on_#{ type }", *args) #rescue r($!, event)
      else
        on_default(type, args)
      end
    end

    def on_default(type, event_args)
      return unless event_args # no-args event
      event_args.each do |arg|
        if arg == nil
          # empty arg - pass

          # why the following isn't reported with scanner events?
        elsif type == :call && [:".", :"::"].include?(arg)
        elsif type == :var_ref && [:".", :"::"].include?(arg)
        elsif type == :field && [:".", :"::"].include?(arg)
        elsif type == :command_call && ([:".", :"::"].include?(arg) || arg == false)
        elsif type == :args_add_block && arg == false
        elsif type == :unary && arg.is_a?(Symbol)
        elsif type == :binary && arg.is_a?(Symbol)
        elsif scanner_event?(arg)
          # scanner event - pass
        elsif (parser_events?(arg) rescue false) # r(type, event_args)
          arg.each do |event|
            walk(event)
          end
        elsif parser_event?(arg)
          walk(arg)
        end
      end
    end

    # Theses are here mainly to document parameters of respective events
    module ParserEvents
      def on_program(body)
        keep_walking(body)
      end

      def on_def(name, params, body)
        keep_walking(name, params, body)
      end

      def on_defs(target, period, name, params, body)
        keep_walking(target, period, name, params, body)
      end

      def on_class(name, ancestor, body)
        keep_walking(name, ancestor, body)
      end

      def on_sclass(target, body)
        keep_walking(target, body)
      end

      def on_module(name, body)
        keep_walking(name, body)
      end

      def on_do_block(params, body)
        keep_walking(params, body)
      end

      def on_brace_block(params, body)
        keep_walking(params, body)
      end

      def on_assign(lhs, rhs)
        keep_walking(lhs, rhs)
      end

      def on_massign(mlhs, mrhs)
        keep_walking(mlhs, mrhs)
      end

      def on_command(operation, command_args)
        keep_walking(operation, command_args)
      end

      def on_fcall(operation)
        keep_walking(operation)
      end

      def on_method_add_arg(method, arguments)
        keep_walking(method, arguments)
      end

      def on_command_call(*args)
        # def on_command_call(receiver, dot, method, args)
        keep_walking(*args)
      end

      def on_call(receiver, dot, method)
        keep_walking(receiver, dot, method)
      end

      def on_var_ref(ref_event)
        keep_walking(ref_event)
      end

      def on_const_path_ref(primary_value, name)
        keep_walking(primary_value, name)
      end
    end
    include ParserEvents

    module ScannerEvents
      def on_const_ref(const_ref_event)
        keep_walking(const_ref_event)
      end
    end
    include ScannerEvents

    def keep_walking(*args)
      on_default(nil, args)
    end

    def scanner_event?(event)
      event.is_a?(Hash)
    end

    def parser_event?(event)
      event.is_a?(Array) && event[0].is_a?(Symbol)
    end

    def parser_events?(events)
      events.all? { |event| parser_event?(event) }
    end

    def is_ident?(event)
      scanner_event?(event) && event[:ident]
    end
  end
end