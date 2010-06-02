module Scholarly::Scholars
  class ValidatesPresenceOfBelongsTo < Scholarly::Base
    self.code_class = "RailsCode"
    self.path_glob = "app/models/**/*.rb"
    self.studies_descendants_of = "ActiveRecord::Base"

    attr_reader :proper, :wrong, :none 

    def initialize(*args)
      super
      @proper = []
      @wrong = []
      @none = []
      @self_test_failures = []
    end

    def study(class_level_statements, env)
      self.files_count += 1

      belongs_to = []
      validates_presence_of = []

      for statement in class_level_statements
        statement = ignore_block(statement)
        if name = extract_command(statement)
          if name == "belongs_to"
            args = command_args(statement)

            if args[0].class.in?(Symbol, String)
              belongs_to << args[0].to_s
            end
          elsif name == "validates_presence_of"
            args = command_args(statement)
            args.select { |arg| arg.class.in?(Symbol, String) }.each do |arg|
              validates_presence_of << arg.to_s
            end
          end
        end
      end

      for assoc in belongs_to
        assoc_validated = false
        for validated_column in validates_presence_of
          if validated_column == assoc
            assoc_validated = true
            self.wrong << { :file => env[:file], :assoc_name => assoc }
          elsif validated_column == "#{ assoc }_id"
            assoc_validated = true
            self.proper << { :file => env[:file], :assoc_name => assoc }
          end
        end
        unless assoc_validated
          self.none << { :file => env[:file], :assoc_name => assoc }
        end
      end

      # self_test(env, belongs_to.size)
    end

    def self_test(env, total_belongs_to_count)
      source = reject_comments(IO.read(env[:file]))

      if (count = source.scan(/\bbelongs_to\s/).size) != total_belongs_to_count  
        @self_test_failures << { :title => "#{ count } belongs_to detected with grep while #{ total_belongs_to_count } detected with parser",
                                 :file => env[:file] }
      end
    end
  end
end