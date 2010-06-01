require "scholarly/descendant_filter"
require "scholarly/sexp_builder_with_scanner_events"

describe Scholarly::DescendantFilter do
  def filter(source)
    class_def = Scholarly::SexpBuilderWithScannerEvents.new(source).parse
    Scholarly::DescendantFilter.new(class_def[1])
  end

  it "returns immediate descendants of given class" do
    src = <<-SRC
      class C < D
      end
    SRC
    filter(src).descendants_of("D").should == [[:class,
                                                [:const_ref, {:const=>"C"}],
                                                [:var_ref, {:const=>"D"}],
                                                [:bodystmt, [[:void_stmt]],
                                                 nil,
                                                 nil,
                                                 nil]]] 
  end

  it "skips non descendants of given class" do
    src = <<-SRC
      class C < E
      end
    SRC
    filter(src).descendants_of("D").should == []
  end

  it "skips classes without base class" do
    src = <<-SRC
      class C
      end
    SRC
    filter(src).descendants_of("D").should == []
  end

  it "returns descendants of given class specified with const_path" do
    src = <<-SRC
      class C < D::E
      end
    SRC
    filter(src).descendants_of("D::E").should == [[:class,
                                                   [:const_ref, {:const=>"C"}],
                                                   [:const_path_ref, [:var_ref, {:const=>"D"}], {:const=>"E"}],
                                                   [:bodystmt,
                                                    [[:void_stmt]],
                                                    nil,
                                                    nil,
                                                    nil]]]
  end
end
