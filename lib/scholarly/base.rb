require "scholarly/sexp_builder_with_scanner_events"
require "scholarly/descendant_filter"
require "dolzenko/error_print"

require "pp"

module Scholarly
  # Scholars base class
  class Base
    class_attribute :studies_descendants_of,
                    :path_glob,
                    :code_class,
                    :studies_whole_ast 

    attr_accessor :files_count

    def initialize
      self.files_count = 0
    end

    def self.run!
      scholar = new
      klass = code_class.constantize
      
      klass.find_each(:conditions => {:clone_state => "cloned"},
                      :batch_size => 100) do |ruby_code|
        study_ruby_code(ruby_code, scholar)
      end
      scholar
    end

    def self.study_ruby_code(ruby_code, scholar = new)
      ruby_code.each_file(path_glob) do |source, file|
        study_source(source, scholar, file)
      end
      scholar 
    end

    def self.study_source(source, scholar = new, file = "(eval)")
      ast = parse_source(source, file)

      if studies_whole_ast
        scholar.study(ast, { :file => file })
      else
        descendants = DescendantFilter.new(ast[1]).descendants_of(studies_descendants_of)

        for descendant in descendants
          body_statement = descendant[3][1]

          class_level_statements = ClassLevelStatementsFilter.filter(body_statement)

          scholar.study(class_level_statements, { :file => file })
        end
      end
      scholar
    end

    def self.parse_source(source, file)
      begin
        parser = SexpBuilderWithScannerEvents.new(source)
        ast = parser.parse
        raise "empty AST" if ast.nil? || ast.empty?
        ast
      rescue Exception => e
        raise if e.class.name.in?(["IRB::Abort", "Interrupt"])
        puts "Exception thrown while trying to parse #{ file }:"
        e.set_backtrace(Rails.backtrace_cleaner.clean(e.backtrace))
        puts e.error_print
        return
      end
    end

    def self.run_file!(path)
      source = IO.read(path)
      ast = SexpBuilderWithScannerEvents.new(source).parse

      descendants = DescendantFilter.new(ast[1]).descendants_of(studies_descendants_of)

      scholar = new
      for descendant in descendants

        body_statement = descendant[3][1]
        filter = ClassLevelStatementsFilter.new(body_statement)
        filter.walk
        class_level_statements = filter.statements
#               puts class_level_statements.inspect
        scholar.study(class_level_statements, { :file => path })
      end
      scholar
    end

    def reject_comments(src)
      src.split("\n").reject { |l| l =~ /^\s*#/ }.join("\n")
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
  end
end
