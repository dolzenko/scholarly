require "scholarly/ast_evaluator"
require "scholarly/sexp_builder_with_scanner_events"

require "pp"

describe Scholarly::AstEvaluator do
  def parse_and_eval(source)
    ast = Scholarly::SexpBuilderWithScannerEvents.new(source).parse
    Scholarly::AstEvaluator.eval(ast[1])
  end

  it "evaluates symbols to their original form" do
    parse_and_eval(":some_symbol").should == [:some_symbol]
  end

  it "evaluates strings to their original form" do
    parse_and_eval("'qwe'").should == ['qwe']
  end

  it "evaluates integers to their original form" do
    parse_and_eval("123").should == [123]
  end

  it "evaluates floats to their original form" do
    parse_and_eval("123.456").should == [123.456]
  end

  it "evaluates lists of evaluatables to their original form" do
    parse_and_eval("[:symbol, 'string', 123]").should == [[:symbol, 'string', 123]]
  end

  it "evaluates hash of evaluatables to their original form" do
    parse_and_eval("{:symbol => 'string', 123 => :symbol}").should == [{:symbol => 'string', 123 => :symbol}]
  end

  it "evaluates constant references to ConstRef object" do
    parse_and_eval("SomeConst")[0].should == Scholarly::AstEvaluator::ConstRef.new("SomeConst")
  end

  it "evaluates top constant references to ConstRef object" do
    parse_and_eval("::SomeConst")[0].should == Scholarly::AstEvaluator::ConstRef.new("::SomeConst")
  end

  it "evaluates path constant references to ConstRef object" do
    parse_and_eval("SomeConst::Another")[0].should == Scholarly::AstEvaluator::ConstRef.new("SomeConst::Another")
  end

  it "evaluates true" do
    parse_and_eval("true").should == [true]
  end

  it "evaluates false" do
    parse_and_eval("false").should == [false]
  end

  it "evaluates nil" do
    parse_and_eval("nil").should == [nil]
  end

  it "evaluates non evaluatable to NonEvaluatable" do
    parse_and_eval("qwe")[0].should be_instance_of(Scholarly::AstEvaluator::NonEvaluatable)
  end

  it "evaluates non evaluatable to NonEvaluatable in array" do
    parse_and_eval("[qwe, 123]")[0][0].should be_instance_of(Scholarly::AstEvaluator::NonEvaluatable)
  end

  it "evaluates non evaluatable to NonEvaluatable in hash" do
    parse_and_eval("{ qwe => 123 }")[0].keys[0].should be_instance_of(Scholarly::AstEvaluator::NonEvaluatable)
  end

  it "evaluates non evaluatable to NonEvaluatable in interpolated string" do
    parse_and_eval('"qwe#{qwe}qwe"')[0].should be_instance_of(Scholarly::AstEvaluator::NonEvaluatable)
  end

  it "evaluates non evaluatable to NonEvaluatable in interpolated symbol" do
    parse_and_eval(':"qwe#{qwe}qwe"')[0].should be_instance_of(Scholarly::AstEvaluator::NonEvaluatable)
  end

  it "evaluates method arguments with hash" do
    # delegate :asd, :qwe, :to => :zxc
    ast = [[:symbol_literal,
            [:symbol, {:ident=>"asd"}]],
           [:symbol_literal,
            [:symbol, {:ident=>"qwe"}]],
           [:bare_assoc_hash,
            [[:assoc_new,
              [:symbol_literal, [:symbol, {:ident=>"to"}]],
              [:symbol_literal, [:symbol, {:ident=>"zxc"}]]],
             [:assoc_new,
              [:symbol_literal, [:symbol, {:ident=>"zxc"}]],
              [:symbol_literal, [:symbol, {:ident=>"asd"}]]]]]]
    Scholarly::AstEvaluator.eval(ast).should == [:asd, :qwe, { :to => :zxc, :zxc => :asd }]
  end
end
