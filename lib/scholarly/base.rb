require "scholarly/sexp_builder_with_scanner_events"
require "scholarly/descendant_filter"
require "dolzenko/error_print"

require "pp"

module Scholarly
  # Scholars base class
  class Base
    class_attribute :studies_descendants_of,
                    :path_glob

    
    def self.run!
      scholar = new
      for rails_code in RailsCode.all
        next unless File.directory?(rails_code.path)

        for file in Dir[File.join(rails_code.path, path_glob)]
          # puts file
          source = IO.read(file)
          # source = @source
          next if source.strip.empty?

          begin
            ast = SexpBuilderWithScannerEvents.new(source).parse

            descendants = DescendantFilter.new(ast[1]).descendants_of(studies_descendants_of)

            for descendant in descendants

              body_statement = descendant[3][1]
              filter = ClassLevelStatementsFilter.new(body_statement)
              filter.walk
              class_level_statements = filter.statements
#               puts class_level_statements.inspect
              scholar.study(class_level_statements, { :file => file })
            end
          rescue Exception => e
            raise if e.class.name.in?(["IRB::Abort", "Interrupt"])
            puts "Exception thrown while trying to parse #{ file }:"
            puts e.error_print
            next
          end
        end
      end
      scholar
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
  end
end
