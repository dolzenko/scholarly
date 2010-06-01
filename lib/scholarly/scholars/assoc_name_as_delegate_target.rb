module Scholarly::Scholars
  class AssocNameAsDelegateTarget < Scholarly::Base
    self.path_glob = "app/models/**/*.rb"
    self.studies_descendants_of = "ActiveRecord::Base"

    attr_reader :delegate_calls, :assoc_calls, :self_test_failures,
                :delegates_to_assoc, :delegates, :files_count

    ASSOC_METHOD_NAMES = %w(has_one belongs_to has_many has_and_belongs_to_many has_many_polymorphs)

    def initialize(*args)
      super
      @delegate_calls = []
      @assoc_calls = []

      @delegates_to_assoc = []
      @delegates = []

      @self_test_failures = []

      @files_count = 0
    end

    def study(class_level_statements, environment)
      delegates_to = []
      assoc_names = []

      @files_count += 1
      
      for statement in class_level_statements
        statement = ignore_block(statement)
        if name = extract_command(statement)
          if name == "delegate"
            args = command_args(statement)
            register_delegate(statement, environment)

            if args[-1].is_a?(Hash) && args[-1][:to]
              delegates_to << args[-1][:to].to_s
            end
          elsif name.in?(ASSOC_METHOD_NAMES)
            args = command_args(statement)
            register_assoc(statement, environment)

            if args[0].class.in?(Symbol, String)
              assoc_names << args[0].to_s
            end
          end
        end
      end

      if (delegates_to & assoc_names).present?
        self.delegates_to_assoc << environment[:file]
      elsif delegates_to.present?
        self.delegates << environment[:file]
      end

      self_test(environment)
    end

    def extract_command(statement)
      if statement[0] == :command &&
              statement[1].is_a?(Hash) &&
              statement[1][:ident]
        statement[1][:ident]
      end
    end

    def command_args(command_statement)
      Scholarly::AstEvaluator.eval(command_statement[2][1])
    end

    def ignore_block(statement)
      if statement[0] == :method_add_block
        statement[1]
      else
        statement
      end
    end

    def register_delegate(command_statement, environment)
      arguments = Scholarly::AstEvaluator.eval(command_statement[2][1])
      @delegate_calls << { :file => environment[:file], :arguments => arguments }
    end

    def register_assoc(command_statement, environment)
      arguments = Scholarly::AstEvaluator.eval(command_statement[2][1])
      @assoc_calls << "assoc #{ arguments.inspect }"
    end

    def self_test(environment)
      source = reject_comments(IO.read(environment[:file]))
      
      if (count = source.scan(/\bdelegate\s/).size) != @delegate_calls.size
        @self_test_failures << { :title => "#{ count } delegate detected with grep while #{ @delegate_calls.size } detected with parser",
                                 :file => environment[:file],
                                 :info => @delegate_calls }
      end

      if (count = source.scan(/\b(#{ ASSOC_METHOD_NAMES.join("|") })\s[^$]/).size) != @assoc_calls.size
        @self_test_failures << { :title => "#{ count } assoc detected with grep while #{ @assoc_calls.size } detected with parser",
                                 :file => environment[:file],
                                 :info => @assoc_calls }
      end
    end

    def reject_comments(src)
      src.split("\n").reject { |l| l =~ /^\s*#/ }.join("\n")
    end
  end
end
