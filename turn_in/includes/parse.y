// Generated by transforming |cwd:///work-in-progress/2.7.2-bisonified.y| on 2016-11-23 at 15:46:56 +0000

%{
	#include <iostream>
	#include <cstring>
	#include <vector>
	
	#include "includes/ast.h"
	#include "includes/tableManager.h"
	class Node;
	
	using std::endl;
	using std::cout;
	using std::string;
	
	int yylex (void);
	extern char *yytext;
	void yyerror (const char *);
	PoolOfNodes& pool = PoolOfNodes::getInstance();
	
	int scopeLevel = 0; // 0 is global, 1 is in one function, 2 is in a nested function
	
	/* Implementation Notes:
	Print statements, assignments (of vars or functions), and function calls are their own "little trees".
	When they are in the global scope, they are evaluated immediately after being written
	There are 4 corresponding nodes: 
		print nodes
		assignment nodes (for vars)
		function nodes (for function definition)
		function calls
		
	Function definitions in the global scope are stored in the global symbol table (in the table manager), any nested ones are stored as subtrees within them
	
	3 things can happen to a function: defined, put in symbol table, called. Unclear what "eval()" means.
	
		When we see a function def, we want the function defined, and (iff in the current scope) put in the current symbol table. 
	
		When called, we want all the functions inside it (but not it) put into the current symbol table.
		
		______________
		new version of notes
		---------------
		different meanings of eval:
			print
		
	*/
	
%}

%token AMPEREQUAL AMPERSAND AND AS ASSERT AT BACKQUOTE BAR BREAK CIRCUMFLEX
%token CIRCUMFLEXEQUAL CLASS COLON COMMA CONTINUE DEDENT DEF DEL DOT DOUBLESLASH
%token DOUBLESLASHEQUAL DOUBLESTAR DOUBLESTAREQUAL ELIF ELSE ENDMARKER EQEQUAL
%token EQUAL EXCEPT EXEC FINALLY FOR FROM GLOBAL GREATER GREATEREQUAL GRLT
%token IF IMPORT IN INDENT IS LAMBDA LBRACE LEFTSHIFT LEFTSHIFTEQUAL LESS
%token LESSEQUAL LPAR LSQB MINEQUAL MINUS NAME NEWLINE NOT NOTEQUAL
%token OR PASS PERCENT PERCENTEQUAL PLUS PLUSEQUAL PRINT RAISE RBRACE RETURN
%token RIGHTSHIFT RIGHTSHIFTEQUAL RPAR RSQB SEMI SLASH SLASHEQUAL STAR STAREQUAL
%token STRING TILDE TRY VBAREQUAL WHILE WITH YIELD
// removed NUMBER, added INT, FLOAT
%token FLOAT INT

%start start

%locations

%union{
	Node* node_p;
	SuiteNode* suite_node_p;
	char* c_string;
	int int_val;
	float float_val;
}
%type<c_string> NAME

%type<node_p> atom 
%type<node_p> arith_expr power factor term opt_test 
%type<node_p> opt_yield_test pick_yield_expr_testlist_comp testlist_comp test
%type< node_p> pick_yield_expr_testlist star_EQUAL expr_stmt testlist 
%type<node_p> star_COMMA_test yield_expr or_test lambdef plus_STRING
%type<node_p> funcdef print_stmt

%type<suite_node_p> plus_stmt stmt suite

%type<int_val>INT pick_PLUS_MINUS pick_multop pick_unop augassign and_test star_trailer
%type<float_val> FLOAT

%%

start
	: file_input
	;
file_input // Used in: start
	: star_NEWLINE_stmt ENDMARKER
	;
pick_NEWLINE_stmt // Used in: star_NEWLINE_stmt
	: NEWLINE
	| stmt
	{ 
		if ($1){
			//$1->display();
		}
	}
	;
star_NEWLINE_stmt // Used in: file_input, star_NEWLINE_stmt
	: star_NEWLINE_stmt pick_NEWLINE_stmt
	| %empty
	;
decorator // Used in: decorators
	: AT dotted_name LPAR opt_arglist RPAR NEWLINE
	| AT dotted_name NEWLINE
	;
opt_arglist // Used in: decorator, trailer
	: arglist
	| %empty
	;
decorators // Used in: decorators, decorated
	: decorators decorator
	| decorator
	;
decorated // Used in: compound_stmt
	: decorators classdef
	| decorators funcdef
	;
funcdef // Used in: decorated, compound_stmt
	: DEF NAME parameters COLON suite
	{ 	
		IdentNode* name = new IdentNode($2);
		pool.add(name);
		
		FuncNode* func = new FuncNode($5); // later: pass parameters too
		pool.add(func);
		
		FuncAsgNode* asg = new FuncAsgNode(name, func);
		pool.add(asg);
			
		if (scopeLevel == 0){
			asg->eval();
		} else {
			$$ = asg;
		}
		free($2);
	}
	;
parameters // Used in: funcdef
	: LPAR varargslist RPAR
	| LPAR RPAR
	;
varargslist // Used in: parameters, old_lambdef, lambdef
	: star_fpdef_COMMA pick_STAR_DOUBLESTAR
	| star_fpdef_COMMA fpdef opt_EQUAL_test opt_COMMA
	;
opt_EQUAL_test // Used in: varargslist, star_fpdef_COMMA
	: EQUAL test
	{ cout << "eq" << endl; }
	| %empty
	;
star_fpdef_COMMA // Used in: varargslist, star_fpdef_COMMA
	: star_fpdef_COMMA fpdef opt_EQUAL_test COMMA
	| %empty
	;
opt_DOUBLESTAR_NAME // Used in: pick_STAR_DOUBLESTAR
	: COMMA DOUBLESTAR NAME
	{ free($3); }
	| %empty
	;
pick_STAR_DOUBLESTAR // Used in: varargslist
	: STAR NAME opt_DOUBLESTAR_NAME
	{ free($2); }
	| DOUBLESTAR NAME
	{ free($2); }
	;
opt_COMMA // Used in: varargslist, opt_test, opt_test_2, testlist_safe, listmaker, testlist_comp, pick_for_test_test, pick_for_test, pick_argument
	: COMMA
	| %empty
	;
fpdef // Used in: varargslist, star_fpdef_COMMA, fplist, star_fpdef_notest
	: NAME
	{ free($1); }
	| LPAR fplist RPAR
	{ cout << "lpar for fpdef" << endl; }
	;
fplist // Used in: fpdef
	: fpdef star_fpdef_notest COMMA
	| fpdef star_fpdef_notest
	;
star_fpdef_notest // Used in: fplist, star_fpdef_notest
	: star_fpdef_notest COMMA fpdef
	| %empty
	;
stmt // Used in: pick_NEWLINE_stmt, plus_stmt
	: simple_stmt
	| compound_stmt
	;
simple_stmt // Used in: stmt, suite
	: small_stmt star_SEMI_small_stmt SEMI NEWLINE
	| small_stmt star_SEMI_small_stmt NEWLINE
	;
star_SEMI_small_stmt // Used in: simple_stmt, star_SEMI_small_stmt
	: star_SEMI_small_stmt SEMI small_stmt
	| %empty
	;
small_stmt // Used in: simple_stmt, star_SEMI_small_stmt
	: expr_stmt
	| print_stmt
	| del_stmt
	| pass_stmt
	| flow_stmt
	| import_stmt
	| global_stmt
	| exec_stmt
	| assert_stmt
	;
expr_stmt // Used in: small_stmt
	: testlist augassign pick_yield_expr_testlist
	{ 	
		Node* temp = NULL; 
		if ( $2 == PLUSEQUAL ){
			temp = new AddBinaryNode($1, $3);
		} else if ( $2 == MINEQUAL){
			temp = new SubBinaryNode($1, $3);
		} else if ( $2 == STAREQUAL){
			temp = new MulBinaryNode($1, $3);
		} else if ( $2 == SLASHEQUAL){
			temp = new DivBinaryNode($1, $3);
		} else if ( $2 == PERCENTEQUAL){
			temp = new ModBinaryNode($1, $3);
		} else if ( $2 == DOUBLESLASHEQUAL){
			temp = new DoubleSlashBinaryNode($1, $3);
		} else if ( $2 == DOUBLESTAREQUAL){
			temp = new PowBinaryNode($1, $3);
		}
		
		pool.add(temp);	
		$$ = new AsgBinaryNode($1, temp);
		pool.add($$);
		if (scopeLevel == 0){
			$$->eval();
		}
	} 
	| testlist star_EQUAL
	{ 
		if ($2){
			$$ = new AsgBinaryNode($1, $2);
			pool.add($$);
			if (scopeLevel == 0){
				$$->eval();
			}
		}
	}
	;
pick_yield_expr_testlist // Used in: expr_stmt, star_EQUAL
	: yield_expr
	| testlist
	;
star_EQUAL // Used in: expr_stmt, star_EQUAL
	: star_EQUAL EQUAL pick_yield_expr_testlist
	{ 	if ($1 == NULL){
			$$ = $3;
		} else { // $1 is itself a literal node, so make an assignment node and pass it up
			$$ = new AsgBinaryNode($1, $3);
			pool.add($$);
			if (scopeLevel == 0){
				$$->eval();
			}
		}
	}
	| %empty
	{ $$ = NULL; }
	;
augassign // Used in: expr_stmt
	: PLUSEQUAL
	{ $$ = PLUSEQUAL; }
	| MINEQUAL
	{ $$ = MINEQUAL; }
	| STAREQUAL
	{ $$ = STAREQUAL; }
	| SLASHEQUAL
	{ $$ = SLASHEQUAL; }
	| PERCENTEQUAL
	{ $$ = PERCENTEQUAL; }
	| AMPEREQUAL
	{ $$ = 0; }
	| VBAREQUAL
	{ $$ = 0; }
	| CIRCUMFLEXEQUAL
	{ $$ = 0; }
	| LEFTSHIFTEQUAL 
	{ $$ = 0; }
	| RIGHTSHIFTEQUAL 
	{ $$ = 0; }
	| DOUBLESTAREQUAL 
	{ $$ = DOUBLESTAREQUAL; }
	| DOUBLESLASHEQUAL
	{ $$ = DOUBLESLASHEQUAL; }
	;
print_stmt // Used in: small_stmt
	: PRINT opt_test
	{ 	
		PrintNode* printNode = new PrintNode($2);
		pool.add(printNode);
		if (scopeLevel == 0){
			printNode->eval();
		} else {
			$$ = printNode;
		}
	}
	| PRINT RIGHTSHIFT test opt_test_2
	;
star_COMMA_test // Used in: star_COMMA_test, opt_test, listmaker, testlist_comp, testlist, pick_for_test
	: star_COMMA_test COMMA test
	| %empty
	{ $$ = NULL; }
	;
opt_test // Used in: print_stmt
	: test star_COMMA_test opt_COMMA
	| %empty
	{ $$ = NULL; }
	;
plus_COMMA_test // Used in: plus_COMMA_test, opt_test_2
	: plus_COMMA_test COMMA test
	| COMMA test
	;
opt_test_2 // Used in: print_stmt
	: plus_COMMA_test opt_COMMA
	{ cout << "opt_test_2" << endl; }
	| %empty
	;
del_stmt // Used in: small_stmt
	: DEL exprlist
	;
pass_stmt // Used in: small_stmt
	: PASS
	;
flow_stmt // Used in: small_stmt
	: break_stmt
	| continue_stmt
	| return_stmt
	| raise_stmt
	| yield_stmt
	;
break_stmt // Used in: flow_stmt
	: BREAK
	;
continue_stmt // Used in: flow_stmt
	: CONTINUE
	;
return_stmt // Used in: flow_stmt
	: RETURN testlist
	| RETURN
	;
yield_stmt // Used in: flow_stmt
	: yield_expr
	;
raise_stmt // Used in: flow_stmt
	: RAISE test opt_test_3
	| RAISE
	;
opt_COMMA_test // Used in: opt_test_3, exec_stmt
	: COMMA test
	| %empty
	;
opt_test_3 // Used in: raise_stmt
	: COMMA test opt_COMMA_test
	| %empty
	;
import_stmt // Used in: small_stmt
	: import_name
	| import_from
	;
import_name // Used in: import_stmt
	: IMPORT dotted_as_names
	;
import_from // Used in: import_stmt
	: FROM pick_dotted_name IMPORT pick_STAR_import
	;
pick_dotted_name // Used in: import_from
	: star_DOT dotted_name
	| star_DOT DOT
	;
pick_STAR_import // Used in: import_from
	: STAR
	| LPAR import_as_names RPAR
	| import_as_names
	;
import_as_name // Used in: import_as_names, star_COMMA_import_as_name
	: NAME AS NAME
	{ 
		free($1);
		free($3);
	}
	| NAME
	{ free($1); }
	;
dotted_as_name // Used in: dotted_as_names
	: dotted_name AS NAME
	{ free($3); }	
	| dotted_name
	;
import_as_names // Used in: pick_STAR_import
	: import_as_name star_COMMA_import_as_name COMMA
	| import_as_name star_COMMA_import_as_name
	;
star_COMMA_import_as_name // Used in: import_as_names, star_COMMA_import_as_name
	: star_COMMA_import_as_name COMMA import_as_name
	| %empty
	;
dotted_as_names // Used in: import_name, dotted_as_names
	: dotted_as_name
	| dotted_as_names COMMA dotted_as_name
	;
dotted_name // Used in: decorator, pick_dotted_name, dotted_as_name, dotted_name
	: NAME
	{ free($1); }
	| dotted_name DOT NAME
	{ free($3); }
	;
global_stmt // Used in: small_stmt
	: GLOBAL NAME star_COMMA_NAME
	{ free($2);
	}
	;
star_COMMA_NAME // Used in: global_stmt, star_COMMA_NAME
	: star_COMMA_NAME COMMA NAME
	{ free($3); }
	| %empty
	;
exec_stmt // Used in: small_stmt
	: EXEC expr IN test opt_COMMA_test
	| EXEC expr
	;
assert_stmt // Used in: small_stmt
	: ASSERT test COMMA test
	| ASSERT test
	;
compound_stmt // Used in: stmt
	: if_stmt
	| while_stmt
	| for_stmt
	| try_stmt
	| with_stmt
	| funcdef
	| classdef
	| decorated
	;
if_stmt // Used in: compound_stmt
	: IF test COLON suite star_ELIF ELSE COLON suite
	| IF test COLON suite star_ELIF
	;
star_ELIF // Used in: if_stmt, star_ELIF
	: star_ELIF ELIF test COLON suite
	| %empty
	;
while_stmt // Used in: compound_stmt
	: WHILE test COLON suite ELSE COLON suite
	| WHILE test COLON suite
	;
for_stmt // Used in: compound_stmt
	: FOR exprlist IN testlist COLON suite ELSE COLON suite
	{ 
		// example of alternative method $$ = 1 + $6 + $9; 
		
	}
	| FOR exprlist IN testlist COLON suite
	;
	
try_stmt: TRY try_stmt_ending 

try_stmt_ending // Used in: compound_stmt
	: COLON suite plus_except opt_ELSE opt_FINALLY
	| COLON suite FINALLY COLON suite
	;
plus_except // Used in: try_stmt, plus_except
	: plus_except except_clause COLON suite
	| except_clause COLON suite
	;
opt_ELSE // Used in: try_stmt
	: ELSE COLON suite
	| %empty
	;
opt_FINALLY // Used in: try_stmt
	: FINALLY COLON suite
	| %empty
	;
with_stmt // Used in: compound_stmt
	: WITH with_item star_COMMA_with_item COLON suite
	;
star_COMMA_with_item // Used in: with_stmt, star_COMMA_with_item
	: star_COMMA_with_item COMMA with_item
	| %empty
	;
with_item // Used in: with_stmt, star_COMMA_with_item
	: test AS expr
	| test
	;
except_clause // Used in: plus_except
	: EXCEPT test opt_AS_COMMA
	| EXCEPT
	;
pick_AS_COMMA // Used in: opt_AS_COMMA
	: AS
	| COMMA
	;
opt_AS_COMMA // Used in: except_clause
	: pick_AS_COMMA test
	| %empty
	;
suite // Used in: funcdef, if_stmt, star_ELIF, while_stmt, for_stmt, try_stmt, plus_except, opt_ELSE, opt_FINALLY, with_stmt, classdef
	: simple_stmt
	{
		cout << "simple_stmt" << endl; 
	}
	| { scopeLevel++; } NEWLINE INDENT plus_stmt DEDENT { scopeLevel--; }
	{
		$$ = $4;
	}
	;
plus_stmt // Used in: suite, plus_stmt
	: plus_stmt stmt
	{
		$1->addStatement($2);
	}
	| stmt
	{ 
		$$ = new SuiteNode();
		pool.add($$);
		$$->addStatement($1);
	}
	;
testlist_safe // Used in: list_for
	: old_test plus_COMMA_old_test opt_COMMA
	| old_test
	;
plus_COMMA_old_test // Used in: testlist_safe, plus_COMMA_old_test
	: plus_COMMA_old_test COMMA old_test
	| COMMA old_test
	;
old_test // Used in: testlist_safe, plus_COMMA_old_test, old_lambdef, list_if, comp_if
	: or_test
	| old_lambdef
	;
old_lambdef // Used in: old_test
	: LAMBDA varargslist COLON old_test
	| LAMBDA COLON old_test
	;
test // Used in: opt_EQUAL_test, print_stmt, star_COMMA_test, opt_test, plus_COMMA_test, raise_stmt, opt_COMMA_test, opt_test_3, exec_stmt, assert_stmt, if_stmt, star_ELIF, while_stmt, with_item, except_clause, opt_AS_COMMA, opt_IF_ELSE, listmaker, testlist_comp, lambdef, subscript, opt_test_only, sliceop, testlist, dictorsetmaker, star_test_COLON_test, opt_DOUBLESTAR_test, pick_argument, argument, testlist1
	: or_test opt_IF_ELSE
	| lambdef
	;
opt_IF_ELSE // Used in: test
	: IF or_test ELSE test 
	| %empty
	;
or_test // Used in: old_test, test, opt_IF_ELSE, or_test, comp_for
	: and_test
	| or_test OR and_test
	;
and_test // Used in: or_test, and_test
	: not_test
	| and_test AND not_test
	;
not_test // Used in: and_test, not_test
	: NOT not_test
	| comparison
	;
comparison // Used in: not_test, comparison
	: expr
	| comparison comp_op expr
	;
comp_op // Used in: comparison
	: LESS
	| GREATER
	| EQEQUAL
	| GREATEREQUAL
	| LESSEQUAL
	| GRLT
	| NOTEQUAL
	| IN
	| NOT IN
	| IS
	| IS NOT
	;
expr // Used in: exec_stmt, with_item, comparison, expr, exprlist, star_COMMA_expr
	: xor_expr
	| expr BAR xor_expr
	;
xor_expr // Used in: expr, xor_expr
	: and_expr
	| xor_expr CIRCUMFLEX and_expr
	;
and_expr // Used in: xor_expr, and_expr
	: shift_expr
	| and_expr AMPERSAND shift_expr
	;
shift_expr // Used in: and_expr, shift_expr
	: arith_expr
	| shift_expr pick_LEFTSHIFT_RIGHTSHIFT arith_expr
	;
pick_LEFTSHIFT_RIGHTSHIFT // Used in: shift_expr
	: LEFTSHIFT
	| RIGHTSHIFT
	;
arith_expr // Used in: shift_expr, arith_expr
	: term
	{ $$ = $1; }
	| arith_expr pick_PLUS_MINUS term
	{ 	
		if( $2 == PLUS ){
			$$ = new AddBinaryNode($1, $3);
			pool.add($$);
		} else if ($2 == MINUS ) {
			$$ = new SubBinaryNode($1, $3);
			pool.add($$);
		}
	}
	;
pick_PLUS_MINUS // Used in: arith_expr
	: PLUS
	{ $$ = PLUS; }
	| MINUS
	{ $$ = MINUS; }
	;
term // Used in: arith_expr, term
	: factor
	{	$$ = $1;  }
	| term pick_multop factor
	{ 
		// todo do the operation then pass up the result
		int operation = $2;
		if (operation == STAR){
			$$ = new MulBinaryNode($1, $3);
			pool.add($$);
		} else if ( operation == SLASH ){
			$$ = new DivBinaryNode($1, $3);
			pool.add($$);
		} else if ( operation == PERCENT ){
			$$ = new ModBinaryNode($1, $3);
			pool.add($$);
		} else if ( operation == DOUBLESLASH ){
			$$ = new DoubleSlashBinaryNode($1, $3);
			pool.add($$);
		}
	}
	;
pick_multop // Used in: term
	: STAR
	{ $$ = STAR; }
	| SLASH
	{ $$ = SLASH; }
	| PERCENT
	{ $$ = PERCENT; }
	| DOUBLESLASH
	{ $$ = DOUBLESLASH; } 
	;
factor // Used in: term, factor, power
	: pick_unop factor
	{ 	int pick_unop = $1;
		Node* factor = $2;
		if ( pick_unop == MINUS){
			factor->changeSign();
		}
		$$ = factor;
	}
	| power
	{ $$ = $1; }
	;
pick_unop // Used in: factor
	: PLUS
	{ $$ = PLUS; }
	| MINUS
	{ $$ = MINUS; }
	| TILDE
	{ $$ = TILDE; }
	;
power // Used in: factor
	: atom star_trailer DOUBLESTAR factor
	{ 	$$ = new PowBinaryNode($1, $4);
		pool.add($$);
	}
	| atom star_trailer
	{	
		if($2){ // function calls
			$$ = new CallNode(static_cast<IdentNode*>($1) );
			pool.add($$);
			$$->eval();
		} else { // just an atom (number, name, etc.)
			$$ = $1; 	
		}
	}
	;
star_trailer // Used in: power, star_trailer // eg (3, 2) in foo(3, 2)
	: star_trailer trailer
	{ $$ = 1; }
	| %empty
	{ $$ = 0; }
	; 
atom // Used in: power
	: LPAR opt_yield_test RPAR
	{ $$ = $2; }
	| LSQB opt_listmaker RSQB
	{ $$ = NULL; }
	| LBRACE opt_dictorsetmaker RBRACE
	{ $$ = NULL; }
	| BACKQUOTE testlist1 BACKQUOTE
	{ $$ = NULL; }
	| NAME
	{ 	
		$$ = new IdentNode($1);
		pool.add($$);
		free($1); 
	}
	| INT
	{ 	$$ = new IntLiteral($1);        
        pool.add($$);
	}
	| FLOAT
	{ 	$$ = new FloatLiteral($1);
		pool.add($$);
	}
	| plus_STRING
	;
pick_yield_expr_testlist_comp // Used in: opt_yield_test
	: yield_expr
	| testlist_comp
	;
opt_yield_test // Used in: atom
	: pick_yield_expr_testlist_comp
	| %empty
	{ $$ = NULL; }
	;
opt_listmaker // Used in: atom
	: listmaker
	| %empty
	;
opt_dictorsetmaker // Used in: atom
	: dictorsetmaker
	| %empty
	;
plus_STRING // Used in: atom, plus_STRING
	: plus_STRING STRING
	| STRING
	{ $$ = NULL; }
	;
listmaker // Used in: opt_listmaker
	: test list_for
	| test star_COMMA_test opt_COMMA
	;
testlist_comp // Used in: pick_yield_expr_testlist_comp
	: test comp_for
	{ cout <<"test comp_for" << endl; // doesn't get here
	}
	| test star_COMMA_test opt_COMMA
	;
lambdef // Used in: test
	: LAMBDA varargslist COLON test
	{ $$ = NULL; }
	| LAMBDA COLON test
	{ $$ = NULL; }
	;
trailer // Used in: star_trailer
	: LPAR opt_arglist RPAR
	{ 
		// "lpar for trailer" 
	}
	| LSQB subscriptlist RSQB
	| DOT NAME
	{ free($2); }
	;
subscriptlist // Used in: trailer
	: subscript star_COMMA_subscript COMMA
	| subscript star_COMMA_subscript
	;
star_COMMA_subscript // Used in: subscriptlist, star_COMMA_subscript
	: star_COMMA_subscript COMMA subscript
	| %empty
	;
subscript // Used in: subscriptlist, star_COMMA_subscript
	: DOT DOT DOT
	| test
	| opt_test_only COLON opt_test_only opt_sliceop
	;
opt_test_only // Used in: subscript
	: test
	| %empty
	;
opt_sliceop // Used in: subscript
	: sliceop
	| %empty
	;
sliceop // Used in: opt_sliceop
	: COLON test
	| COLON
	;
exprlist // Used in: del_stmt, for_stmt, list_for, comp_for
	: expr star_COMMA_expr COMMA
	{ cout << "exprlist" << endl; }
	| expr star_COMMA_expr
	{ cout << "exprlist" << endl; }
	;
star_COMMA_expr // Used in: exprlist, star_COMMA_expr
	: star_COMMA_expr COMMA expr
	| %empty
	;
testlist // Used in: expr_stmt, pick_yield_expr_testlist, return_stmt, for_stmt, opt_testlist, yield_expr
	: test star_COMMA_test COMMA
	| test star_COMMA_test
	;
dictorsetmaker // Used in: opt_dictorsetmaker
	: test COLON test pick_for_test_test
	| test pick_for_test
	;
star_test_COLON_test // Used in: star_test_COLON_test, pick_for_test_test
	: star_test_COLON_test COMMA test COLON test
	| %empty
	;
pick_for_test_test // Used in: dictorsetmaker
	: comp_for
	| star_test_COLON_test opt_COMMA
	;
pick_for_test // Used in: dictorsetmaker
	: comp_for
	| star_COMMA_test opt_COMMA
	;
classdef // Used in: decorated, compound_stmt
	: CLASS NAME LPAR opt_testlist RPAR COLON suite
	{ free($2); }
	| CLASS NAME COLON suite
	{ free($2); }
	;
opt_testlist // Used in: classdef
	: testlist
	| %empty
	;
arglist // Used in: opt_arglist
	: star_argument_COMMA pick_argument
	;
star_argument_COMMA // Used in: arglist, star_argument_COMMA
	: star_argument_COMMA argument COMMA
	| %empty
	;
star_COMMA_argument // Used in: star_COMMA_argument, pick_argument
	: star_COMMA_argument COMMA argument
	| %empty
	;
opt_DOUBLESTAR_test // Used in: pick_argument
	: COMMA DOUBLESTAR test
	| %empty
	;
pick_argument // Used in: arglist
	: argument opt_COMMA
	| STAR test star_COMMA_argument opt_DOUBLESTAR_test
	| DOUBLESTAR test
	;
argument // Used in: star_argument_COMMA, star_COMMA_argument, pick_argument
	: test opt_comp_for
	| test EQUAL test
	{ cout << "argument" << endl; }
	;
opt_comp_for // Used in: argument
	: comp_for
	| %empty
	;
list_iter // Used in: list_for, list_if
	: list_for
	| list_if
	;
list_for // Used in: listmaker, list_iter
	: FOR exprlist IN testlist_safe list_iter
	{ 
		//list comprehension
	 }
	| FOR exprlist IN testlist_safe
	{ 
		//list comprehension
	}
	;
list_if // Used in: list_iter
	: IF old_test list_iter
	| IF old_test
	;
comp_iter // Used in: comp_for, comp_if
	: comp_for
	| comp_if
	;
comp_for // Used in: testlist_comp, pick_for_test_test, pick_for_test, opt_comp_for, comp_iter
	: FOR exprlist IN or_test comp_iter
	{ 
		// weird "for" (generator?)
	}
	| FOR exprlist IN or_test
	{
		// weird "for"
	}
	;
comp_if // Used in: comp_iter
	: IF old_test comp_iter
	| IF old_test
	;
testlist1 // Used in: atom, testlist1
	: test
	| testlist1 COMMA test
	;
yield_expr // Used in: pick_yield_expr_testlist, yield_stmt, pick_yield_expr_testlist_comp
	: YIELD testlist
	{ $$ = NULL; }
	| YIELD 
	{ $$ = NULL; }
	;
star_DOT // Used in: pick_dotted_name, star_DOT
	: star_DOT DOT
	| %empty
	;

%%

#include <stdio.h>
void yyerror (const char *s)
{
    if(yylloc.first_line > 0)	{
        fprintf (stderr, "%d.%d-%d.%d:", yylloc.first_line, yylloc.first_column,
	                                     yylloc.last_line,  yylloc.last_column);
    }
    fprintf(stderr, " %s with [%s]\n", s, yytext);
}


