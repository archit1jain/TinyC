#include "translator.h"
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
symbol_table* globalST = new symbol_table();
symbol_table* currentST=globalST;
vector<quad> quad_array;
vector<string> string_label;

int symbol_table::temp_count=0;

row* symbol_table::lookup(const string &name)
{
	if(hash_table_names.find(name)==hash_table_names.end())
	{row r;
		size++;
	hash_table_names[name]=num_rows++;
	r.Name=name;
	symb_table.push_back(r);
	return &symb_table[num_rows-1];}
	else return &symb_table[hash_table_names[name]];
}

row* symbol_table::gentemp(symbol_table &Table)
{
	Table.size++;
	char temp_no[5];
	row temp;
	sprintf(temp_no,"t%d",temp_count++);
	string temp_label(temp_no);
	Table.hash_table_names[temp_label]=Table.num_rows++;
	temp.Name=temp_label;
	Table.symb_table.push_back(temp);
	return &(Table.symb_table[Table.num_rows-1]);
}

void symbol_table::update(const string &s,const row& f)
{
	row* fn=lookup(s);
	fn->Name=f.Name;
	fn->typ_vector=f.typ_vector;
	fn->Typ=f.Typ;
	fn->offset=f.offset;
	fn->nestedTable=f.nestedTable;
	fn->init_val=f.init_val;
	fn->size=f.size;
}

void symbol_table::print()
{	ofstream file;
	file.open("quads.out",ofstream::app);
	file<<"No of parameters = "<<param_count<<endl;
	file<<"<=====================Symbol Table===================>\n";
	for (int i = 0; i < symb_table.size(); ++i){
		row &ro=symb_table[i];
		if(ro.Name=="-1")continue;
		if(ro.nestedTable!=NULL)ro.Typ=functiontype;
		file<<"|"<<i<<" | "<<ro.Name<<" | ";
		if(ro.Typ==0)file<<"int | ";
		if(ro.Typ==1)file<<"double | ";
		if(ro.Typ==2)file<<"char | ";
		if(ro.Typ==3){
			for(int i=0;i<ro.typ_vector.size();i++){
				file<<"array("<<ro.typ_vector[i].first<<",";
				if(ro.typ_vector[i].second==3)continue;
			}
			if(ro.typ_vector[0].second==0){file<<"int";}
			if(ro.typ_vector[0].second==1){file<<"double";}
			if(ro.typ_vector[0].second==2){file<<"char";}
			for(int j=0;j<ro.typ_vector.size();j++)file<<")";
			file<<" | ";
		}
		if(ro.Typ==4)file<<"function | ";
		if(ro.Typ==5)file<<"ptr_int | ";
		if(ro.Typ==6)file<<"ptr_double | ";
		if(ro.Typ==7)file<<"ptr_char | ";
		if(ro.Typ==8)file<<"void | ";
		if(ro.Typ==9)file<<"string | ";
		if(ro.init_val=="")file<<"null";
		else file<<ro.init_val;
		file<<" | "<<ro.size<<" | "<<ro.offset<<" | "<<ro.ebpoffset<<" | ";
		if(ro.nestedTable!=NULL)
			{file<<"ptr-to-ST(func)|\n";
		}
		else file<<"null |\n";
	}
	file<<"<====================================================>\n\n\n";
	for(int i=0;i<symb_table.size();i++){
		row &ro=symb_table[i];
		if(ro.nestedTable!=NULL){
		file<<"\n\n<======================"<<ro.Name<<"===========================>\n\n";
		ro.nestedTable->print();
		}
	}
	file.close();
}

void symbol_table::correctST(){
	symbol_table* temp;
	int i=0;
	while(i<size){
		if(symb_table[i].Name=="main"){temp=symb_table[i].nestedTable;}
		if(symb_table[i].Typ==functiontype){temp=(symb_table[i].nestedTable);
			i++;
			continue;
		}
		temp->lookup(symb_table[i].Name);
		temp->update(symb_table[i].Name,symb_table[i]);
		i++;
	}
	i=0;
	while(i<size){if(symb_table[i].Typ!=functiontype)symb_table[i].Name="-1";i++;}
}

void symbol_table::activationRecord(){
	int i=0,eoffset=4;
	while(i<param_count){
		eoffset+=symb_table[i].size;
		symb_table[i].ebpoffset=eoffset;
		i++;
	}
	if(symb_table[i].Name=="RetVal"){
		symb_table[i].ebpoffset=4;
		i++;
	}
	eoffset=0;
	while(i<size){
		if(symb_table[i].Typ==functiontype){symb_table[i].nestedTable->activationRecord();}
		eoffset-=symb_table[i].size;
		symb_table[i].ebpoffset=eoffset;
		i++;
	}
}

symbol_table::symbol_table():num_rows(0),size(0),param_count(0)
{symb_table.reserve(500);}

quad::quad(string op1, char *re, char *a1, char *a2)
:op(op1), result(strdup(re)), arg1(strdup(a1)), arg2(strdup(a2)){}

quad::quad(string op1,const string &re,const string &a1,const string &a2)
:op(op1),result(strdup(re.c_str())),arg1(strdup(a1.c_str())),arg2(strdup(a2.c_str()))
{}

quad::quad(string op1,const string &re,const string &a1)
:op(op1),result(strdup(re.c_str())),arg1(strdup(a1.c_str())),arg2(NULL)
{}

quad::quad(string op1, char *re,char* a1,int a1num)
:op(op1),result(strdup(re)),arg1(strdup(a1))
{
	arg2=new char[10];
	sprintf(arg2,"%d",a1num);
}

quad::quad(string op1, const string &re,const string &a1,int a1num):op(op1),result(strdup(re.c_str())),arg1(strdup(a1.c_str())){
	arg2=new char[10];
	sprintf(arg2,"%d",a1num);	
}

quad::quad(char* re,char* a1)
:op(""),result(strdup(re)),arg1(strdup(a1)),arg2(NULL){}

quad::quad(const string &re,const string &a1)
:op(""),result(strdup(re.c_str())),arg1(strdup(a1.c_str())),arg2(NULL)
{}

quad::quad(string op1,int no)
:op(op1),arg2(NULL),arg1(NULL)
{
	result = new char[10];
	sprintf(result,"%d",no);
}

void quad::emit(const quad &q,int index){
	ofstream file;
	file.open("quads.out",ofstream::app);
	file<<index<<" : ";
	char s[]="param";
	if(q.arg2!=NULL&&q.arg1!=NULL){
		if(q.op=="[]=")file<<q.result<<"["<<q.arg1<<"]"<<" = "<<q.arg2<<endl;
		else if(q.op=="=[]")file<<q.result<<" = "<<q.arg1<<"["<<q.arg2<<"]\n";
		else if(q.op=="+"||q.op=="-"||q.op=="*"||q.op=="/"||q.op=="%"||q.op=="=")file<<q.result<<" = "<<q.arg1<<q.op<<q.arg2<<endl;
		else if(q.op=="|"||q.op=="^"||q.op=="&")file<<q.result<<" = "<<q.arg1<<q.op<<q.arg2<<endl;
		else if(q.op=="call")file<<q.arg1<<" = call "<<q.result<<" , "<<q.arg2<<endl;
		else file<<"if "<<q.arg1<<q.op<<q.arg2<<" goto "<<q.result<<endl;
	}
	else if(q.arg2==NULL&&q.op!=""){
		if(q.op=="goto")file<<"goto "<<q.result<<endl;
		else if(q.op=="return")file<<"return "<<q.result<<endl;
		else if(q.op=="if")file<<"if "<<q.arg1<<" goto "<<q.result<<endl;
		else if(q.op=="&"||q.op=="*"||q.op=="+"||q.op=="-"||q.op=="~"||q.op=="!")file<<q.result<<" = "<<q.op<<q.arg1<<endl;
		else if(q.op=="funcstart")file<<"start "<<q.result<<" :\n";
		else if(q.op=="funcend")file<<"end "<<q.result<<" :\n";
	}
	else if(q.result[0]=='p'&&q.result[1]=='a'&&q.result[2]=='r')file<<q.result<<" "<<q.arg1<<endl;
	else file<<q.result<<" = "<<q.arg1<<endl;
	file.close();
}

void backpatch(const list &v,int index)
{
	for (int i=0;i<v.size();++i){
		char temp[20];
		sprintf(temp,"%d",index);
		quad_array[v[i]].setresult(temp);
	}
}

int typecheck(struct row* r1,struct row* r2)
{
	if(r1->Typ!=r2->Typ)return false;
	else {
		if(r1->typ_vector.size()!=r2->typ_vector.size())
		return false;
		for(int i=0;i<r1->typ_vector.size();++i){
			pair<int,int> x=r1->typ_vector[i],y=r2->typ_vector[i];
			if(x.second!=y.second)return false;}
	}
	return true;
}

list merge(const list &l1,const list &l2){
	list L(l1);
	L.insert(L.end(),l2.begin(),l2.end());
	return L;
}

list makelist(int index){
	list v;
	v.push_back(index);
	return v;
}