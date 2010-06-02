module Scholarly::Scholars
  class AssocNameAsDelegateTarget < Scholarly::Base
    self.code_class = "RailsCode"
    self.path_glob = "app/models/**/*.rb"
    self.studies_descendants_of = "ActiveRecord::Base"

    attr_reader :delegates_to_association, :delegates_to_else

    ASSOC_METHOD_NAMES = %w(has_one belongs_to has_many has_and_belongs_to_many has_many_polymorphs)

    def initialize(*args)
      super
      @delegate_calls = []
      @assoc_calls = []

      @delegates_to_association = []
      @delegates_to_else = []

      @self_test_failures = []
    end

    def study(class_level_statements, env)
      delegation_targets = []
      association_names = []

      self.files_count += 1
      
      for statement in class_level_statements
        statement = ignore_block(statement)
        if name = extract_command(statement)
          if name == "delegate"
            args = command_args(statement)

            if args[-1].is_a?(Hash) && args[-1][:to]
              delegation_targets << args[-1][:to].to_s
            end
          elsif name.in?(ASSOC_METHOD_NAMES)
            args = command_args(statement)

            if args[0].class.in?(Symbol, String)
              association_names << args[0].to_s
            end
          end
        end
      end

      for delegation_target in delegation_targets
        delegate_info = { :file => env[:file],
                          :delegation_target => delegation_target }

        if association_names.include?(delegation_target)
          self.delegates_to_association << delegate_info
        else
          self.delegates_to_else << delegate_info
        end
      end

      # self_test(environment)
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
  end
end
