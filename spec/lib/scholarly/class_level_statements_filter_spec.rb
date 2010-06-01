require "scholarly/sexp_builder_with_scanner_events"
require "scholarly/class_level_statements_filter"

require "pp"

describe Scholarly::ClassLevelStatementsFilter do
  def statements(source)
    class_def = Scholarly::SexpBuilderWithScannerEvents.new(source).parse
    body_statement = class_def[1][0][3][1]
    filter = Scholarly::ClassLevelStatementsFilter.new(body_statement)
    filter.walk
    filter.statements
  end

  it "filters nested module definition" do
    statements(<<-SRC).should == []
      class C
        module M
        end
      end
    SRC
  end

  it "filters nested class definition" do
    statements(<<-SRC).should == []
      class C
        class M
        end
      end
    SRC
  end

  it "filters method definition" do
    statements(<<-SRC).should == []
      class C
        def m
        end
      end
    SRC
  end

  it "filters singleton method definition" do
    statements(<<-SRC).should == []
      class C
        def self.m
        end
      end
    SRC
  end

  it "leaves class level method invocation (with paren)" do
    statements(<<-SRC).should == [[:method_add_arg, [:fcall, {:ident=>"asd"}], [:arg_paren, nil]]]
      class C
        asd()
      end
    SRC
  end

  it "leaves class level method invocation (without paren)" do
    statements(<<-SRC).should == [[:var_ref, {:ident=>"asd"}]]
      class C
        asd
      end
    SRC
  end

  it "leaves delegate macro invocation" do
    src = <<-SRC
      class C
        delegate :asd, :qwe, :to => :zxc
      end
    SRC

    statements(src).should == [[:command,
                                {:ident=>"delegate"},
                                [:args_add_block,
                                 [[:symbol_literal,
                                   [:symbol, {:ident=>"asd"}]],
                                  [:symbol_literal,
                                   [:symbol, {:ident=>"qwe"}]],
                                  [:bare_assoc_hash,
                                   [[:assoc_new,
                                     [:symbol_literal, [:symbol, {:ident=>"to"}]],
                                     [:symbol_literal, [:symbol, {:ident=>"zxc"}]]]]]],
                                 false]]]
  end

  it "leaves belongs_to macro invocation" do
    src = <<-SRC
      class C
        belongs_to :asd
      end
    SRC

    statements(src).should == [[:command,
                                {:ident=>"belongs_to"},
                                [:args_add_block, 
                                 [[:symbol_literal,
                                   [:symbol, {:ident=>"asd"}]]],
                                 false]]]
  end

  it "leaves belongs_to macro invocation with block" do
    src = <<-SRC
      class C
        belongs_to :asd do
        end
      end
    SRC

    statements(src).should == [[:method_add_block,
                                [:command,
                                 {:ident=>"belongs_to"},
                                 [:args_add_block,
                                  [[:symbol_literal,
                                    [:symbol, {:ident=>"asd"}]]],
                                  false]], 
                                [:do_block, nil, [[:void_stmt]]]]]
  end
end