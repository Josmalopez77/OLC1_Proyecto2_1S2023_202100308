/* Gramatica */
%{
	var cadena = '';
	var errors = [];
%}
%lex

%options case-insensitive
%x string

%%

\s+                   				// Espacios en blanco
"//".*								// Comentario de una linea
[/][*][^*]*[*]+([^/*][^*]*[*]+)*[/]	// Comentario Multilinea
//=======Datos Primitivos===============
"double"             	return 'DOUBLE'
"int"             		return 'INTEGER'
"boolean"              	return 'BOOLEAN'
"char"             		return 'CHAR'
"string"				return 'STRING'
//======================================
//=================Sentencias De Control===================
"new"					return 'NEW'
"if"					return 'TK_IF'
"else"					return 'TK_ELSE'
"switch"				return 'TK_SWITCH'
"case"					return 'TK_CASE'
"break"					return 'TK_BREAK'
//==========================================================
//===============Sentencias cíclicas=========================
"while"               	return 'TK_WHILE'
"for"					return 'TK_FOR'
"do"					return 'TK_DO'
//===========================================================
"default"				return 'TK_DEFAULT'
"continue"				return 'TK_CONTINUE'
"return"				return 'TK_RETURN'
"void"					return 'TK_VOID'
//============= Incremento y Decremento=============
"++"					return 'INCREMENTO'
"--"					return 'DECREMENTO'
//==================================================
//==================Funciones Nativas=======================
"println"				return 'PRINTLN'
"print"					return 'PRINT'
"toLower"				return 'TK_TOLOWER'
"toUpper"				return 'TK_TOUPPER'
"length"				return 'TK_LENGTH'
"round"					return 'TK_ROUND'
"typeof"				return 'TK_TYPEOF'
"toString"				return 'TK_TOSTRING'
"toCharArray"			return 'TK_TOCHARARRAY'
"run"					return 'TK_RUN'
"main"					return 'TK_MAIN'
//==========================================================
"true"                	return 'TRUE'
"false"               	return 'FALSE'
//============Operadores Lógicos================
"||"                   	return 'OR'
"&&"                   	return 'AND'
//===============================================
//============Operadores Relacionales=================
"!="                   	return 'DIFERENTEA'
"=="                   	return 'IGUALIGUAL'
"!"                   	return 'NOT'
"="						return 'IGUAL'
"<="                   	return 'MENORIGUAL'
">="					return 'MAYORIGUAL'
">"                   	return 'MAYOR'
"<"                   	return 'MENOR'
//===================================================
//==============Coma y Punto y coma=================
","                   	return 'COMA'
";"                   	return 'TK_PYC'
//==================================================
":"						return 'DOSPUNTS'
"{"                   	return 'LlaveAbre'
"}"                   	return 'LlaveCierra'
//============Operadores Numéricos================
"*"                   	return 'OP_MULTIPLICACION'
"/"                   	return 'OP_DIVISION'
"-"                   	return 'OP_MENOS'
"+"                   	return 'OP_SUMA'
"^"                   	return 'OP_EXPONENTE'
"%"                   	return 'OP_MODULO'
//================================================
//============Signos De Agrupación=====================
"("                   	return 'PARENTESIS_ABRE'
")"                   	return 'PARENTESIS_CIERRA'
"?"						return 'OP_TERNARIO'
"["						return 'COR_ABRE'
"]"						return 'COR_CIERRA'
//=====================================================

([a-zA-Z])([a-zA-Z0-9_])* return 'IDENTIFICADOR'
[']\\\\[']|[']\\\"[']|[']\\\'[']|[']\\n[']|[']\\t[']|[']\\r[']|['].?[']	return 'CARACTER'
[0-9]+("."[0-9]+)+\b	return 'DECI'
[0-9]+					return 'ENTERO'

["]						{ cadena = ''; this.begin("string"); }
<string>[^"\\]+			{ cadena += yytext; }
<string>"\\\""			{ cadena += "\""; }
<string>"\\n"			{ cadena += "\n"; }
<string>\s				{ cadena += " ";  }
<string>"\\t"			{ cadena += "\t"; }
<string>"\\\\"			{ cadena += "\\"; }
<string>"\\\'"			{ cadena += "\'"; }
<string>"\\r"			{ cadena += "\r"; }
<string>["]				{ yytext = cadena; this.popState(); return 'CADENA'; }

<<EOF>>               	return 'EOF'
.                     	{ errors.push({ tipo: "Léxico", error: yytext, linea: yylloc.first_line, columna: yylloc.first_column+1 }); return 'INVALID'; } 

/lex
// Importaciones
%{
	const TIPO_OPERACION	= require('./Controller/Principales/TOperaciones');
	const TIPO_VALOR 		= require('./Controller/Principales/TValores');
	const TIPO_DATO			= require('./Controller/Principales/Tipos');
	const INSTRUCCION		= require('./controller/Instruccion/Instruccion');
%}

/* Precedencias */

%left 'OP_TERNARIO'
%left 'OR'
%left 'AND'
%right 'NOT'
%left 'IGUALIGUAL' 'DIFERENTEA' 'MENOR' 'MENORIGUAL' 'MAYOR' 'MAYORIGUAL'
%left 'OP_SUMA' 'OP_MENOS'
%left 'OP_MULTIPLICACION' 'OP_DIVISION' 'OP_MODULO'
%left 'OP_EXPONENTE'
%left 'INCREMENTO','DECREMENTO'
%left umenos
%left 'PARENTESIS_ABRE'

%start ini

%% /* Producciones */

ini: ENTRADA EOF { retorno = { parse: $1, errors: errors }; errors = []; return retorno; }
	| error EOF { retorno = { parse: null, errors: errors }; errors = []; return retorno; }
;

ENTRADA: ENTRADA ENTCERO { if($2!=="") $1.push($2); $$=$1; }
		| ENTCERO {if($1!=="") $$=[$1]; else $$=[]; }
;

ENTCERO: FUNCIONBODY {$$=$1}
		| METODOBODY {$$=$1}
		| MAINBODY {$$=$1}
		| DEC_VAR {$$=$1}
		| DEC_VECT {$$=$1}
;

FUCTIONBODY: TIPO IDENTIFICADOR PARENTESIS_ABRE PARENTESIS_CIERRA LlaveAbre INSTRUCCION LlaveCierra { $$ = INSTRUCCION.nuevaFuncion($2, null, $6, $1, this._$.first_line, this._$.first_column+1) }
			| TIPO IDENTIFICADOR PARENTESIS_ABRE PARENTESIS_CIERRA LlaveAbre LlaveCierra { $$ = INSTRUCCION.nuevaFuncion($2, null, [], $1, this._$.first_line, this._$.first_column+1) }
			| TIPO IDENTIFICADOR PARENTESIS_ABRE LISTAPARAMETROS PARENTESIS_CIERRA LlaveAbre INSTRUCCION LlaveCierra { $$ = INSTRUCCION.nuevaFuncion($2, $4, $7, $1, this._$.first_line, this._$.first_column+1) } 
			| TIPO IDENTIFICADOR PARENTESIS_ABRE LISTAPARAMETROS PARENTESIS_CIERRA LlaveAbre LlaveCierra { $$ = INSTRUCCION.nuevaFuncion($2, $4, [], $1, this._$.first_line, this._$.first_column+1) }
;


METODOBODY: TK_VOID IDENTIFICADOR PARENTESIS_ABRE PARENTESIS_CIERRA LlaveAbre INSTRUCCION LlaveCierra { $$ = INSTRUCCION.nuevoMetodo($2, [], $6, this._$.first_line, this._$.first_column+1) }	
			| TK_VOID IDENTIFICADOR PARENTESIS_ABRE PARENTESIS_CIERRA LlaveAbre LlaveCierra { $$ = INSTRUCCION.nuevoMetodo($2, [], [], this._$.first_line, this._$.first_column+1) }
			| TK_VOID IDENTIFICADOR PARENTESIS_ABRE LISTAPARAMETROS PARENTESIS_CIERRA LlaveAbre INSTRUCCION LlaveCierra { $$ = INSTRUCCION.nuevoMetodo($2, $4, $7, this._$.first_line, this._$.first_column+1) }
			| TK_VOID IDENTIFICADOR PARENTESIS_ABRE LISTAPARAMETROS PARENTESIS_CIERRA LlaveAbre LlaveCierra { $$ = INSTRUCCION.nuevoMetodo($2, $4, [], this._$.first_line, this._$.first_column+1) }
			| TK_VOID error LlaveCierra { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Declaración de método/Función no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
;

MAINBODY: TK_MAIN IDENTIFICADOR PARENTESIS_ABRE PARENTESIS_CIERRA TK_PYC {$$ = INSTRUCCION.nuevoRun($2, null, this._$.first_line, this._$.first_column+1)}
			| TK_MAIN IDENTIFICADOR PARENTESIS_ABRE LISTAVALORES PARENTESIS_CIERRA TK_PYC {$$ = INSTRUCCION.nuevoRun($2, $4, this._$.first_line, this._$.first_column+1)}
			| TK_MAIN error TK_PYC { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Llamada de Run no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); } 
;
RUNBODY: TK_RUN  IDENTIFICADOR PARENTESIS_ABRE PARENTESIS_CIERRA TK_PYC {$$ = INSTRUCCION.nuevoRun($2, null, this._$.first_line, this._$.first_column+1)}
			| TK_RUN  IDENTIFICADOR PARENTESIS_ABRE LISTAVALORES PARENTESIS_CIERRA TK_PYC {$$ = INSTRUCCION.nuevoRun($2, $4, this._$.first_line, this._$.first_column+1)}
			| TK_RUN  error TK_PYC { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Llamada de Run no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
;

LISTAPARAMETROS: LISTAPARAMETROS COMA PARAMETROS {$1.push($3); $$=$1;}
				| PARAMETROS {$$=[$1];}
;

PARAMETROS: TIPO IDENTIFICADOR COR_ABRE COR_CIERRA {$$ = INSTRUCCION.nuevoParametro($2, {vector: $1}, this._$.first_line, this._$.first_column+1)}
			| TIPO IDENTIFICADOR {$$ = INSTRUCCION.nuevoParametro($2, $1, this._$.first_line, this._$.first_column+1)}
;

INSTRUCCION: INSTRUCCION INSCERO { if($2!=="") $1.push($2); $$=$1; }
			| INSCERO { if($1!=="") $$=[$1]; else $$=[]; }
;

INSCERO: DEC_VAR {$$=$1}
		| SENTENCIACONTROL {$$=$1}
		| SENTENCIACICLO {$$=$1}
		| DEC_VECT {$$=$1}
		| SENTENCIATRANSFERENCIA {$$=$1}
		| LLAMADA TK_PYC {$$=$1}
		| FPRINTLN {$$=$1}
		| FPRINT {$$=$1}
		| error TK_PYC { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Declaración de instrucción no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
		| error LlaveCierra { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Declaración de instrucción no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
;

SENTENCIATRANSFERENCIA: TK_BREAK TK_PYC { $$ = new INSTRUCCION.nuevoBreak(this._$.first_line, this._$.first_column+1) }
						| TK_RETURN EXPRESION TK_PYC { $$ = new INSTRUCCION.nuevoReturn($2, this._$.first_line, this._$.first_column+1) }
						| TK_CONTINUE TK_PYC { $$ = new INSTRUCCION.nuevoContinue(this._$.first_line, this._$.first_column+1) }
						| TK_RETURN TK_PYC { $$ = new INSTRUCCION.nuevoReturn(null, this._$.first_line, this._$.first_column+1) }
;

SENTENCIACICLO: WHILE {$$=$1}
				| FOR {$$=$1}
				| DOWHILE {$$=$1}
;

WHILE: TK_WHILE PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre INSTRUCCION LlaveCierra {$$ = new INSTRUCCION.nuevoWhile($3, $6, this._$.first_line,this._$.first_column+1)}
		| TK_WHILE PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre LlaveCierra {$$ = new INSTRUCCION.nuevoWhile($3, [], this._$.first_line,this._$.first_column+1)}
		| TK_WHILE error LlaveCierra { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Declaración de ciclo While no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
;

FOR: TK_FOR PARENTESIS_ABRE DEC_VAR EXPRESION TK_PYC ACTUALIZACION PARENTESIS_CIERRA LlaveAbre INSTRUCCION LlaveCierra {$9.push($6); $$ = new INSTRUCCION.nuevoFor($3, $4, $9, this._$.first_line,this._$.first_column+1)}
	| TK_FOR PARENTESIS_ABRE DEC_VAR EXPRESION TK_PYC ACTUALIZACION PARENTESIS_CIERRA LlaveAbre LlaveCierra { $$ = new INSTRUCCION.nuevoFor($3, $4, [$6], this._$.first_line,this._$.first_column+1)}
	| TK_FOR error LlaveCierra { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Declaración de ciclo For no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
;

ACTUALIZACION: IDENTIFICADOR IGUAL EXPRESION {$$ = INSTRUCCION.nuevaAsignacion($1, $3, this._$.first_line,this._$.first_column+1)}
			| IDENTIFICADOR INCREMENTO {
			$$ = INSTRUCCION.nuevaAsignacion($1,
			{ opIzq: { tipo: 'VAL_IDENTIFICADOR', valor: $1, linea: this._$.first_line, columna: this._$.first_column+1 },
				opDer: { tipo: 'VAL_ENTERO', valor: 1, linea: this._$.first_line, columna: this._$.first_column+1 },  			tipo: 'SUMA',
				linea: this._$.first_line,
				columna: this._$.first_column+1 }, this._$.first_line,this._$.first_column+1)
			}
			| IDENTIFICADOR DECREMENTO {
			$$ = INSTRUCCION.nuevaAsignacion($1,
			{ opIzq: { tipo: 'VAL_IDENTIFICADOR', valor: $1, linea: this._$.first_line, columna: this._$.first_column+1 },
				opDer: { tipo: 'VAL_ENTERO', valor: 1, linea: this._$.first_line, columna: this._$.first_column+1 },
				tipo: 'RESTA',
				linea: this._$.first_line,
				columna: this._$.first_column+1 }, this._$.first_line,this._$.first_column+1)
			}
;

DOWHILE: TK_DO LlaveAbre INSTRUCCION LlaveCierra TK_WHILE PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA TK_PYC {$$ = new INSTRUCCION.nuevoDoWhile($7, $3, this._$.first_line,this._$.first_column+1)}
		| TK_DO LlaveAbre LlaveCierra TK_WHILE PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA TK_PYC {$$ = new INSTRUCCION.nuevoDoWhile($7, [], this._$.first_line,this._$.first_column+1)}
		| TK_DO error TK_PYC { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Declaración de sentencia Do-While no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
;

SENTENCIACONTROL: CONTROLIF {$$=$1}
				| SWITCH {$$=$1}
;

CONTROLIF: IF {$$=$1}
	| IFELSE {$$=$1}
	| ELSEIF {$$=$1}
	| TK_IF error LlaveCierra { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Declaración de sentencia If no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
;

IF: TK_IF PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre INSTRUCCION LlaveCierra { $$ = new INSTRUCCION.nuevoIf($3, $6, this._$.first_line,this._$.first_column+1) }
	| TK_IF PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre LlaveCierra { $$ = new INSTRUCCION.nuevoIf($3, [], this._$.first_line,this._$.first_column+1) }
;

IFELSE: TK_IF PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre INSTRUCCION LlaveCierra TK_ELSE LlaveAbre INSTRUCCION LlaveCierra { $$ = new INSTRUCCION.nuevoIfElse($3, $6, $10, this._$.first_line,this._$.first_column+1) }
		| TK_IF PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre LlaveCierra TK_ELSE LlaveAbre INSTRUCCION LlaveCierra { $$ = new INSTRUCCION.nuevoIfElse($3, [], $9, this._$.first_line,this._$.first_column+1) }
		| TK_IF PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre INSTRUCCION LlaveCierra TK_ELSE LlaveAbre LlaveCierra { $$ = new INSTRUCCION.nuevoIfElse($3, $6, [], this._$.first_line,this._$.first_column+1) }
		| TK_IF PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre LlaveCierra TK_ELSE LlaveAbre LlaveCierra { $$ = new INSTRUCCION.nuevoIfElse($3, [], [], this._$.first_line,this._$.first_column+1) }
;

ELSEIF: TK_IF PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre INSTRUCCION LlaveCierra TK_ELSE CONTROLIF { $$ = new INSTRUCCION.nuevoElseIf($3, $6, $9, this._$.first_line,this._$.first_column+1); }
		| TK_IF PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre LlaveCierra TK_ELSE CONTROLIF { $$ = new INSTRUCCION.nuevoElseIf($3, [], $8, this._$.first_line,this._$.first_column+1); }
;

SWITCH: TK_SWITCH PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre CASESLIST DEFAULT LlaveCierra { $$ = new INSTRUCCION.nuevoSwitch($3, $6, $7, this._$.first_line, this._$.first_column+1); }
		| TK_SWITCH PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre CASESLIST LlaveCierra { $$ = new INSTRUCCION.nuevoSwitch($3, $6, null, this._$.first_line, this._$.first_column+1); }
		| TK_SWITCH PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA LlaveAbre DEFAULT LlaveCierra { $$ = new INSTRUCCION.nuevoSwitch($3, null, $6, this._$.first_line, this._$.first_column+1); }
		| TK_SWITCH error LlaveCierra { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Declaración de sentencia Swtich no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
;

CASESLIST: CASESLIST TK_CASE EXPRESION DOSPUNTS INSTRUCCION { $1.push(new INSTRUCCION.nuevoCaso($3, $5, this._$.first_line, this._$.first_column+1)); $$=$1; }
		| CASESLIST TK_CASE EXPRESION DOSPUNTS { $1.push(new INSTRUCCION.nuevoCaso($3, [], this._$.first_line, this._$.first_column+1)); $$=$1; }
		| TK_CASE EXPRESION DOSPUNTS INSTRUCCION { $$ = [new INSTRUCCION.nuevoCaso($2, $4, this._$.first_line, this._$.first_column+1)]; }
		| TK_CASE EXPRESION DOSPUNTS { $$ = [new INSTRUCCION.nuevoCaso($2, [], this._$.first_line, this._$.first_column+1)]; }
		| TK_CASE error DOSPUNTS { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Declaración de caso no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
;

DEFAULT: TK_DEFAULT DOSPUNTS INSTRUCCION { $$ = new INSTRUCCION.nuevoCaso(null, $3, this._$.first_line, this._$.first_column+1); }
		| TK_DEFAULT DOSPUNTS { $$ = new INSTRUCCION.nuevoCaso(null, [], this._$.first_line, this._$.first_column+1); }
;

DEC_VAR: TIPO IDENTIFICADOR IGUAL EXPRESION TK_PYC {$$ = INSTRUCCION.nuevaDeclaracion($2, $4, $1, this._$.first_line,this._$.first_column+1)}
		| TIPO IDENTIFICADOR TK_PYC {$$ = INSTRUCCION.nuevaDeclaracion($2, null, $1, this._$.first_line,this._$.first_column+1)}
		| IDENTIFICADOR IGUAL EXPRESION TK_PYC {$$ = INSTRUCCION.nuevaAsignacion($1, $3, this._$.first_line,this._$.first_column+1)}
		| IDENTIFICADOR INCREMENTO TK_PYC {
			$$ = INSTRUCCION.nuevaAsignacion($1,
			{ opIzq: { tipo: 'VAL_IDENTIFICADOR', valor: $1, linea: this._$.first_line, columna: this._$.first_column+1 },
				opDer: { tipo: 'VAL_ENTERO', valor: 1, linea: this._$.first_line, columna: this._$.first_column+1 },
				tipo: 'SUMA',
				linea: this._$.first_line,
				columna: this._$.first_column+1 }, this._$.first_line,this._$.first_column+1)
			}
		| IDENTIFICADOR DECREMENTO TK_PYC {
			$$ = INSTRUCCION.nuevaAsignacion($1,
			{ opIzq: { tipo: 'VAL_IDENTIFICADOR', valor: $1, linea: this._$.first_line, columna: this._$.first_column+1 },
				opDer: { tipo: 'VAL_ENTERO', valor: 1, linea: this._$.first_line, columna: this._$.first_column+1 },
				tipo: 'RESTA',
				linea: this._$.first_line,
				columna: this._$.first_column+1 }, this._$.first_line,this._$.first_column+1)
			}
		| TIPO error TK_PYC { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Declaración de variable no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
;

DEC_VECT: TIPO COR_ABRE COR_CIERRA IDENTIFICADOR IGUAL NEW TIPO COR_ABRE EXPRESION COR_CIERRA TK_PYC { $$ = INSTRUCCION.nuevoVector($1, $7, $4, $9, null, null, this._$.first_line, this._$.first_column+1) }
		| TIPO COR_ABRE COR_CIERRA IDENTIFICADOR IGUAL COR_ABRE LISTAVALORES COR_CIERRA TK_PYC { $$ = INSTRUCCION.nuevoVector($1, null, $4, null, $7, null, this._$.first_line, this._$.first_column+1) }
		| IDENTIFICADOR COR_ABRE EXPRESION COR_CIERRA IGUAL EXPRESION { $$ = INSTRUCCION.modificacionVector($1, $3, $6, this._$.first_line, this._$.first_column+1) }
		| TIPO COR_ABRE COR_CIERRA IDENTIFICADOR IGUAL EXPRESION TK_PYC { $$ = INSTRUCCION.nuevoVector($4, null, $1, null, null, $6, this._$.first_line, this._$.first_column+1) }
		| TIPO COR_ABRE COR_CIERRA error TK_PYC { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Declaración de vector no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); } 
;

TIPO: TIPODATO {$$ = $1}
;

TIPODATO: STRING {$$ = TIPO_DATO.CADENA}
		| INTEGER {$$ = TIPO_DATO.ENTERO}
		| DOUBLE {$$ = TIPO_DATO.DOBLE}
		| CHAR {$$ = TIPO_DATO.CARACTER}
		| BOOLEAN {$$ = TIPO_DATO.BOOLEANO}
;

EXPRESION: 	EXPRESION OP_SUMA EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.SUMA,this._$.first_line,this._$.first_column+1);}
			| EXPRESION OP_MENOS EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.RESTA,this._$.first_line,this._$.first_column+1);}
			| EXPRESION OP_MULTIPLICACION EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.MULTIPLICACION,this._$.first_line,this._$.first_column+1);}
			| EXPRESION OP_DIVISION EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.DIVISION,this._$.first_line,this._$.first_column+1);}
			| EXPRESION OP_EXPONENTE EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.POTENCIA,this._$.first_line,this._$.first_column+1);}
			| EXPRESION OP_MODULO EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.MODULO,this._$.first_line,this._$.first_column+1);}
			| OP_MENOS EXPRESION %prec umenos {$$= INSTRUCCION.nuevaOperacionBinaria($2, null, TIPO_OPERACION.NEGACION,this._$.first_line,this._$.first_column+1);}
			| PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA {$$=$2}
			| EXPRESION IGUALIGUAL EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.IGUALIGUAL,this._$.first_line,this._$.first_column+1);}
			| EXPRESION DIFERENTEA EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.DIFERENTE,this._$.first_line,this._$.first_column+1);}
			| EXPRESION MENOR EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.MENOR,this._$.first_line,this._$.first_column+1);}
			| EXPRESION MENORIGUAL EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.MENORIGUAL,this._$.first_line,this._$.first_column+1);}
			| EXPRESION MAYOR EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.MAYOR,this._$.first_line,this._$.first_column+1);}
			| EXPRESION MAYORIGUAL EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.MAYORIGUAL,this._$.first_line,this._$.first_column+1);}
			| EXPRESION OR EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.OR,this._$.first_line,this._$.first_column+1);}
			| EXPRESION AND EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($1,$3, TIPO_OPERACION.AND,this._$.first_line,this._$.first_column+1);}
			| NOT EXPRESION {$$= INSTRUCCION.nuevaOperacionBinaria($2, null, TIPO_OPERACION.NOT,this._$.first_line,this._$.first_column+1);}
			| CADENA {$$ = INSTRUCCION.nuevoValor($1, TIPO_VALOR.CADENA, this._$.first_line,this._$.first_column+1)}
			| CARACTER {$$ = INSTRUCCION.nuevoValor($1.trim().substring(1, $1.length - 1), TIPO_VALOR.CARACTER, this._$.first_line,this._$.first_column+1)}
			| TRUE {$$ = INSTRUCCION.nuevoValor($1.trim(), TIPO_VALOR.BOOLEANO, this._$.first_line,this._$.first_column+1)}
			| FALSE {$$ = INSTRUCCION.nuevoValor($1.trim(), TIPO_VALOR.BOOLEANO, this._$.first_line,this._$.first_column+1)}
			| ENTERO {$$ = INSTRUCCION.nuevoValor(Number($1.trim()), TIPO_VALOR.ENTERO, this._$.first_line,this._$.first_column+1)}
			| DECI {$$ = INSTRUCCION.nuevoValor(Number($1.trim()), TIPO_VALOR.DOBLE, this._$.first_line,this._$.first_column+1)}
			| GETVALUE PARENTESIS_ABRE IDENTIFICADOR COMA EXPRESION PARENTESIS_CIERRA { $$ = INSTRUCCION.accesoLista($3, $5, this._$.first_line, this._$.first_column+1) }
			| IDENTIFICADOR COR_ABRE EXPRESION COR_CIERRA { $$ = INSTRUCCION.accesoVector($1, $3, this._$.first_line, this._$.first_column+1) }
			| IDENTIFICADOR {$$ = INSTRUCCION.nuevoValor($1.trim(), TIPO_VALOR.IDENTIFICADOR, this._$.first_line,this._$.first_column+1)}
			| CASTEO {$$=$1}
			| TERNARIO {$$=$1}
			| LLAMADA {$$=$1}
			| FUNCIONESRESERVADAS {$$=$1}
;

CASTEO: PARENTESIS_ABRE TIPO PARENTESIS_CIERRA EXPRESION { $$ = new INSTRUCCION.nuevoCasteo($2, $4, this._$.first_line, this._$.first_column+1) }
;

TERNARIO: EXPRESION OP_TERNARIO EXPRESION DOSPUNTS EXPRESION { $$ = new INSTRUCCION.nuevoTernario($1, $3, $5, this._$.first_line, this._$.first_column+1) }
;

FUNCIONESRESERVADAS: FTOLOWER {$$=$1}
					| FTOUPPER {$$=$1}
					| FLENGTH {$$=$1}
					| FROUND {$$=$1}
					| FTYPEOF {$$=$1}
					| FTOSTRING {$$=$1}
					| FTOCHARARRAY {$$=$1}
;

FPRINTLN: PRINTLN PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA TK_PYC {$$ = new INSTRUCCION.nuevoImprimirLn($3, this._$.first_line,this._$.first_column+1)}
		| PRINTLN PARENTESIS_ABRE PARENTESIS_CIERRA TK_PYC {$$ = new INSTRUCCION.nuevoImprimirLn(INSTRUCCION.nuevoValor("", TIPO_VALOR.CADENA, this._$.first_line,this._$.first_column+1), this._$.first_line,this._$.first_column+1)}
		| PRINTLN error TK_PYC { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Llamada a función println no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
;

FPRINT: PRINT PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA TK_PYC {$$ = new INSTRUCCION.nuevoImprimir($3, this._$.first_line,this._$.first_column+1)}
		| PRINT PARENTESIS_ABRE PARENTESIS_CIERRA TK_PYC {$$ = new INSTRUCCION.nuevoImprimir(INSTRUCCION.nuevoValor("", TIPO_VALOR.CADENA, this._$.first_line,this._$.first_column+1), this._$.first_line,this._$.first_column+1)}
		| PRINT error TK_PYC { $$ = ""; errors.push({ tipo: "Sintáctico", error: "Llamada a función print no válida.", linea: this._$.first_line, columna: this._$.first_column+1 }); }
;

FTOLOWER: TK_TOLOWER PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA {$$ = new INSTRUCCION.toLower($3, this._$.first_line,this._$.first_column+1)}
;

FTOUPPER: TK_TOUPPER PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA {$$ = new INSTRUCCION.toUpper($3, this._$.first_line,this._$.first_column+1)}
;

FLENGTH: TK_LENGTH PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA {$$ = new INSTRUCCION.nuevoLength($3, this._$.first_line,this._$.first_column+1)}
;

FROUND: TK_ROUND PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA {$$ = new INSTRUCCION.nuevoRound($3, this._$.first_line,this._$.first_column+1)}
;

FTYPEOF: TK_TYPEOF PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA {$$ = new INSTRUCCION.nuevoTypeOf($3, this._$.first_line,this._$.first_column+1)}
;

FTOSTRING: TK_TOSTRING PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA {$$ = new INSTRUCCION.nuevoToString($3, this._$.first_line,this._$.first_column+1)}
;

FTOCHARARRAY: TK_TOCHARARRAY PARENTESIS_ABRE EXPRESION PARENTESIS_CIERRA {$$ = new INSTRUCCION.nuevoToCharArray($3, this._$.first_line,this._$.first_column+1)}
;

LLAMADA: IDENTIFICADOR PARENTESIS_ABRE LISTAVALORES PARENTESIS_CIERRA {$$ = INSTRUCCION.nuevaLlamada($1, $3, this._$.first_line, this._$.first_column+1)}
		| IDENTIFICADOR PARENTESIS_ABRE PARENTESIS_CIERRA {$$ = INSTRUCCION.nuevaLlamada($1, [], this._$.first_line, this._$.first_column+1)}
;

LISTAVALORES: LISTAVALORES COMA VALORES {$1.push($3); $$=$1;}
			| VALORES {$$=[$1];}
;

VALORES: EXPRESION {$$=$1}
;


