#include "translator.h"
#include "y.tab.h"
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
#include <sstream>
using namespace std;
extern vector<quad> quad_array;
extern symbol_table* globalST;
extern vector<string> string_label;
extern int yylex();
extern char* yytext;
ofstream file;
vector<int> labels;

int isNumber(string s){
	int i=0;
	while(i<s.length()&&s[i]>='0'&&s[i]<='9')i++;
	if(i==s.length())return 1;
	else return 0;
}

void function_prologue(symbol_table* &t){
	int min;
	file<<"\tpushl\t%ebp\n";
	file<<"\tmovl\t%esp, %ebp\n";
	for(int i=0;i<t->size;i++)if(i==0||t->symb_table[i].ebpoffset<min)min=t->symb_table[i].ebpoffset;
	if(min<0)file<<"\tsubl\t$"<<-min<<", %esp\n";
}

void function_epilogue(){
	file<<"\tleave\n";
	file<<"\tret\n";
}

void TAC_to_x86(string op,string result,string arg1,string arg2,symbol_table* &t){
	if(arg1!=""&&arg2!=""){
		if(op==">"){
			int i;
			vector<int>::iterator it=find(labels.begin(),labels.end(),atoi(result.c_str()));
			if(it!=labels.end())i=it-labels.begin()+1;
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tcmpl\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tjg\t.L"<<i<<"\n";
		}
		else if(op=="<"){
			int i;
			vector<int>::iterator it=find(labels.begin(),labels.end(),atoi(result.c_str()));
			if(it!=labels.end())i=it-labels.begin()+1;
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tcmpl\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tjl\t.L"<<i<<"\n";
		}
		else if(op==">="){
			int i;
			vector<int>::iterator it=find(labels.begin(),labels.end(),atoi(result.c_str()));
			if(it!=labels.end())i=it-labels.begin()+1;
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tcmpl\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tjge\t.L"<<i<<"\n";
		}
		else if(op=="<="){
			int i;
			vector<int>::iterator it=find(labels.begin(),labels.end(),atoi(result.c_str()));
			if(it!=labels.end())i=it-labels.begin()+1;
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tcmpl\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tjle\t.L"<<i<<"\n";
		}
		else if(op=="=="){
			int i;
			vector<int>::iterator it=find(labels.begin(),labels.end(),atoi(result.c_str()));
			if(it!=labels.end())i=it-labels.begin()+1;
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tcmpl\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tje\t.L"<<i<<"\n";
		}
		else if(op=="!="){
			int i;
			vector<int>::iterator it=find(labels.begin(),labels.end(),atoi(result.c_str()));
			if(it!=labels.end())i=it-labels.begin()+1;
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tcmpl\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tjne\t.L"<<i<<"\n";
		}
		else if(op=="+"){
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			if(arg2!="1")file<<"\taddl\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %eax\n";
			else file<<"\taddl\t$"<<arg2<<", %eax\n";
			file<<"\tmovl\t%eax, "<<t->lookup(result)->ebpoffset<<"(%ebp)\n";
		}
		else if(op=="-"){
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			if(arg2!="1")file<<"\tsubl\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %eax\n";
			else file<<"\tsubl\t$"<<arg2<<", %eax\n";
			file<<"\tmovl\t%eax, "<<t->lookup(result)->ebpoffset<<"(%ebp)\n";
		}
		else if(op=="*"){
			if(isNumber(arg1)==0)file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			else file<<"\tmovl\t$"<<arg1<<", %eax\n";
			if(isNumber(arg2)==0)file<<"\timull\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %eax\n";
			else file<<"\timull\t$"<<arg2<<", %eax\n";
			file<<"\tmovl\t%eax, "<<t->lookup(result)->ebpoffset<<"(%ebp)\n";
		}
		else if(op=="/"){
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n\tcltd";
			file<<"\tidivl\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tmovl\t%eax, "<<t->lookup(result)->ebpoffset<<"(%ebp)\n";
		}
		else if(op=="%"){
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n\tcltd";
			file<<"\tidivl\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tmovl\t%edx, "<<t->lookup(result)->ebpoffset<<"(%ebp)\n";
		}
		else if(op=="=[]"){
			file<<"\tmovl\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp,%eax,1), %edx\n";
			file<<"\tmovl\t%edx, "<<t->lookup(result)->ebpoffset<<"(%ebp)\n";
		}
		else if(op=="[]="){
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tmovl\t"<<t->lookup(arg2)->ebpoffset<<"(%ebp), %edx\n";
			file<<"\tmovl\t%edx, "<<t->lookup(result)->ebpoffset<<"(%ebp,%eax,1)\n";
		}
		else if(op=="call"){
			file<<"\tcall\t"<<result<<endl;
			file<<"\tmovl\t%eax, "<<t->lookup(arg1)->ebpoffset<<"(%ebp)\n";
		}
	}
	else if(op!=""&&arg2==""){
		if(op=="goto"){
			if(result=="-1")function_epilogue();
			else {int i;
			vector<int>::iterator it=find(labels.begin(),labels.end(),atoi(result.c_str()));
			if(it!=labels.end())i=it-labels.begin()+1;
			file<<"\tjmp\t.L"<<i<<"\n";}
		}
		else if(op=="return"){
			file<<"\tmovl\t"<<t->lookup(result)->ebpoffset<<"(%ebp), %eax\n";
		}
		else if(op=="&"){
			file<<"\tleal\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tmovl\t%eax, "<<t->lookup(result)->ebpoffset<<"(%ebp)\n";
		}
		else if(op=="*"){
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tmovl\t(%eax), %eax\n";
			file<<"\tmovl\t%eax, "<<t->lookup(result)->ebpoffset<<"(%ebp)\n";
		}
		else if(op=="-"){
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tnegl\t%eax\n";
			file<<"\tmovl\t%eax, "<<t->lookup(result)->ebpoffset<<"(%ebp)\n";
		}
		else if(op=="+"){
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tmovl\t%eax, "<<t->lookup(result)->ebpoffset<<"(%ebp)\n";
		}
	}
	else if(result=="param "){
		if(t->lookup(arg1)->Typ==stringtype){
			int i=find(string_label.begin(),string_label.end(),t->lookup(arg1)->init_val)-string_label.begin();
			file<<"\tmovl\t$.LC"<<i<<", %eax\n";
		}
		else file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
		file<<"\tpushl\t%eax\n";
	}
	else {
		struct row* r=t->lookup(result);
		if(r->init_val!=""){
			if(r->Typ==stringtype){
			}
			else {
				file<<"\tmovl\t$"<<arg1<<", "<<t->lookup(result)->ebpoffset<<"(%ebp)\n";
			}
		}
		else {
			file<<"\tmovl\t"<<t->lookup(arg1)->ebpoffset<<"(%ebp), %eax\n";
			file<<"\tmovl\t%eax, "<<t->lookup(result)->ebpoffset<<"(%ebp)\n";
		}
	}
}

void x86_conversion(){
	file<<"\t.file\t\"test.c\"\n";
	symbol_table* t;
	if(string_label.size()>0)file<<"\t.section\t.rodata\n";
	for(int i=0;i<string_label.size();i++)file<<".LC"<<i<<":\n\t.string "<<string_label[i].c_str()<<endl;
	file<<"\t.text\n";
	for(int i=0;i<quad_array.size();i++){
		vector<int>::iterator it=find(labels.begin(),labels.end(),i);
		if(it!=labels.end())file<<".L"<<it-labels.begin()+1<<":\n";
		string op,result(quad_array[i].result),arg1,arg2;
		if(quad_array[i].arg1==NULL)arg1="";
		else arg1=quad_array[i].arg1;
		if(quad_array[i].arg2==NULL)arg2="";
		else arg2=quad_array[i].arg2;
		op=quad_array[i].op;
		if(op=="funcstart"){
			file<<"\t.globl "<<result<<"\n";
		  	file<<"\t.type "<<result<<", @function\n";
		  	file<<result<<":\n";
		  	t=globalST->lookup(result)->nestedTable;
		  	function_prologue(t);
		}
		else if(op=="funcend"){
			function_epilogue();
			file<<"\t.size "<<result<<", .-"<<result<<endl;
		}
		else{
			TAC_to_x86(op,result,arg1,arg2,t);
		}
	}
	file<<"\t.ident 	\"GCC: (Ubuntu 4.8.2-19ubuntu1) 4.8.2\"\n\t.section	.note.GNU-stack,\"\",@progbits\n";
}

int main(int argc, char const *argv[])
{
	yyparse();
	globalST->correctST();
	globalST->activationRecord();
	globalST->print();
	for(int i=0;i<quad_array.size();i++){
		quad_array[i].emit(quad_array[i],i);
		string s=quad_array[i].op;
		if((s=="<"||s==">"||s=="<="||s==">="||s=="=="||s=="!=")&&quad_array[i].arg1!=NULL&&quad_array[i].arg2!=NULL)labels.push_back(atoi(quad_array[i].result));
		else if(s=="goto")labels.push_back(atoi(quad_array[i].result));
		else if(s=="if"&&quad_array[i].arg1!=NULL&&quad_array[i].arg2==NULL)labels.push_back(atoi(quad_array[i].result));
	}
	file.open("test.s",ofstream::app);
	x86_conversion();
	file.close();
	return 0;
}