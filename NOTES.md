# Use Cases

1. How often delegate is called with assoc name
  1.1 All descendants of ActiveRecord::Base
  1.2 For every class extract class level code
  1.3 Find delegate calls in class level code and names of delegation target
  1.4 Find assoc defining code (calls to has_one, belongs_to, has_many) and names of association

2. How often belongs_to assoc is presence validated
  1.1
  1.2
  2.1 Find all belongs_to calls and names of assoc
  2.2 Find all validates_presence_of calls and names of validated column

4. How many down migrations
  4.1 All descendants of ActiveRecord::Migration
  4.2 Count if body of self.down is empty

5. API options popularity to named_scope
  1.1
  1.2 Find named_scope calls, extract options

12. How often `delegate` is missing (i.e. written out manually)
  1.1
  1.2
  1.4
  12.1 For ever method check if it's calling assoc name with the name of method

13. What are often `to_proc` uses
  13.1 Extract `to_proc` AST
  13.2 Remove duplicates
  13.3 Present snippets with UI with links

14. Type of code placed at class declarations
  1.1
  1.2

Later

10. How often just :conditions hash is passed to all/first, which combinations
6. unless ... else cases
7. chainged try/&&/alike
8. searching outside of comments
9. research "simple" blocks like comparing or just calling methods 
3. Ruby#1961 Kernel#__dir__
  3.1 with require
  3.2 with File.dirname
  3.3 $0 == __FILE__

# Features

* collect as many source codes as possible
  * collect as many Rails source codes as possible

  
# Statistical Accuracy
654

13
9
77

740
8
8
82

4031
11
8
80

11298
12
8
78


