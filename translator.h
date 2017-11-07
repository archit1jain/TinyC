#ifndef TRANSLATOR_H
#define RANSLATOR_H

#include <iostream>
#include <string>
#include <algorithm>
#include <vector>
#include <cstdio>
#include <utility>
#include <map>
#include <cmath>
#include <stack>
#include <queue>
#include <cstring>
#include <fstream>
using namespace std;

class symbol_table;

typedef vector<pair<int,int> > Type;
typedef vector<int> list;
enum typ{
	inttype=0,
	doubletype=1,
	chartype=2,
	arraytype=3,
	functiontype=4,
	ptr_int=5,
	ptr_double=6,
	ptr_char=7,
	voidtype=8,
	stringtype=9,
};

const int size_types[] = {4,8,1,4,0,8}; //int,double,char,pointer,void

struct row{
	public:
		string Name,init_val;	
		Type typ_vector;
		typ Typ;
		list truelist,falselist,nextlist;
		unsigned int size;
		int offset,ebpoffset;
		bool isconst;
		bool isBoolExp;
		bool isArray;
		symbol_table* nestedTable;
		row():init_val(""),size(4),offset(0),nestedTable(NULL),typ_vector(){
			list truelist(0),falselist(0),nextlist(0);
		}
};

class symbol_table{
	public:
	map<string,int> hash_table_names;
	std::vector<row> symb_table;
	int num_rows;
	symbol_table();
	static int temp_count;
	int size;
	int param_count;
	row* lookup(const string &name);
	static row* gentemp(symbol_table &st);
	void update(const string &s,const row &f);
	void print();
	void correctST();
	void activationRecord();
};

class quad{
public:
	string op;
	char *result,*arg1,*arg2;
	quad(string op1,char *re,char *a1,char *a2=0);
	quad(string op1,const string &re,const string &a1,const string &a2);
	quad(string op1,const string &re,const string &a1);
	quad(string op1,char *re,char* a1,int a1num);
	quad(string op1, const string &re,const string &a1,int a1num);
	quad(char* re,char* a1);
	quad(const string &re,const string &a1);
	quad(string op1,int no);
	void emit(const quad& qua,int index);
	void print();
	inline void setresult(const string &re){
		this->result=strdup(re.c_str());
	}
};

extern vector<quad> quad_array;

list makelist(int index);

list merge(const list &v1,const list &v2);

void backpatch(const list &v,int index);

int typecheck(struct row* f1,struct row* f2);

#endif