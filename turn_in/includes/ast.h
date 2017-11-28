#pragma once

//  Declarations for a calculator that builds an AST
//  and a graphical representation of the AST.
//  by Brian Malloy

#include <iostream>
#include <string>
#include <map>
#include "literal.h"
#include "tableManager.h"

extern void yyerror(const char*);
extern void yyerror(const char*, const char);

class PrintNode: public Node {
public:
	PrintNode(const Node* _printMe): Node(), printMe(_printMe){ }
	~PrintNode(){}
	PrintNode(const PrintNode&)=delete;
	PrintNode& operator=(const PrintNode&)=delete;
	virtual const Literal* eval() const;
	virtual void display() const;
private:
	const Node* printMe;

};
class IdentNode : public Node {
public:
  IdentNode(const std::string& id) : Node(), ident(id) {
  } 
  virtual ~IdentNode() {}
  const std::string getIdent() const { return ident; }
  virtual const Literal* eval() const;
  virtual void display() const;

private:
  const std::string ident;
};

// suite of code statements for a function
class SuiteNode: public Node {
public:
	SuiteNode(): Node(), statements() {}
	~SuiteNode() {}
	SuiteNode(const SuiteNode&)=delete;
	SuiteNode& operator=(const SuiteNode&)=delete;
	virtual const Literal* eval() const;
	void addStatement(const Node*);
	virtual void display() const;

private:
	std::vector<const Node*> statements;
};

// just wrapper right now, but will hold params later
class FuncNode: public Node {
public:
	FuncNode(SuiteNode* _suite): suite(_suite){ }
	~FuncNode(){}
	FuncNode(const FuncNode&)=delete;
	FuncNode& operator=(const FuncNode&)=delete;
	virtual const Literal* eval() const { 
		if(!suite) throw std::string("no suite");
		suite->eval(); 
		return nullptr;
	}
	virtual void display() const { cout << "FuncNode" << endl; if (suite) suite->eval(); }
private:
	SuiteNode* suite;
};

// assign a definition to a function name
// different from AsgBinaryNode b/c it has to call setFunc from the tableManager not setVar
class FuncAsgNode: public Node {
public:
	FuncAsgNode(const IdentNode* _ident, FuncNode* _func):
		ident(_ident)
		,func(_func)
	{	}
	~FuncAsgNode(){}
	FuncAsgNode(const FuncAsgNode&)=delete;
	FuncAsgNode& operator=(const FuncAsgNode&)=delete;
	virtual const Literal* eval() const;
	virtual void display() const;

private:
	const IdentNode* ident;
	const FuncNode* func;	
}; 


class CallNode: public Node {
public:
	CallNode(const IdentNode* _ident): Node(), ident(_ident){}
	~CallNode(){}
	CallNode(const CallNode&)=delete;
	CallNode& operator=(const CallNode&)=delete;
	virtual const Literal* eval() const;
	virtual void display() const;
private:
	const IdentNode* ident;
};

class BinaryNode : public Node {
public:
  BinaryNode(Node* l, Node* r) : Node(), left(l), right(r), is_neg(false) {}
  virtual const Literal* eval() const = 0;
  Node* getLeft()  const { return left; }
  Node* getRight() const { return right; }
  BinaryNode(const BinaryNode&) = delete;
  BinaryNode& operator=(const BinaryNode&) = delete;
  virtual void changeSign(){
	is_neg = !is_neg;
  }
  virtual bool isNegative() const {
	return is_neg;
  }
  virtual void display(){ cout << typeid(*this).name() << endl; }
protected:
  Node *left;
  Node *right;
private:
  bool is_neg;
};

class AsgBinaryNode : public BinaryNode {
public:
  AsgBinaryNode(Node* left, Node* right);
  virtual const Literal* eval() const;
};

class AddBinaryNode : public BinaryNode {
public:
  AddBinaryNode(Node* left, Node* right) : BinaryNode(left, right) { }
  virtual const Literal* eval() const;
};

class SubBinaryNode : public BinaryNode {
public:
  SubBinaryNode(Node* left, Node* right) : BinaryNode(left, right) { }
  virtual const Literal* eval() const;
};

class MulBinaryNode : public BinaryNode {
public:
  MulBinaryNode(Node* left, Node* right) : BinaryNode(left, right) {}
  virtual const Literal* eval() const;
};

class DivBinaryNode : public BinaryNode {
public:
  DivBinaryNode(Node* left, Node* right) : BinaryNode(left, right) { }
  virtual const Literal* eval() const;
};

class DoubleSlashBinaryNode : public BinaryNode {
public:
  DoubleSlashBinaryNode(Node* left, Node* right) : BinaryNode(left, right) { }
  virtual const Literal* eval() const;
};

class ModBinaryNode : public BinaryNode {
public:
  ModBinaryNode(Node* left, Node* right) : BinaryNode(left, right) { }
  virtual const Literal* eval() const;
};

class PowBinaryNode : public BinaryNode {
public:
  PowBinaryNode(Node* left, Node* right) : BinaryNode(left, right) { }
  virtual const Literal* eval() const;
};

