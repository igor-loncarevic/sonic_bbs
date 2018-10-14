{$F+,O+}

Unit 	BBegin;

INTERFACE

Procedure PrintScreen;
Function ProcessKey : Boolean;

IMPLEMENTATION

Uses
  BFiles,
	Config,
	Crt,
	Misc,
	Modem,
	SysOp;

Procedure PrintScreen;
Begin
  WriteLn ('===='+#13#10+'Local Alt-L, Shell Alt-S, Config Alt-C, Esc - Wait');
End;

Function ProcessKey : Boolean;
Var
	Ch:	Char;
Begin
	ProcessKey:=TRUE;
	Ch:=ReadKey;
	If Ch=#0 Then Begin
		Ch:=ReadKey;
		Case Ch Of
			#38 : Local:=TRUE;  (*L*)
			#31	:	Begin (*S*)
              BFiles.WriteAction2Log ('-LOCAL start of shell');
							SysOp.Shell ('');
							ProcessKey:=FALSE;
							Exit;
						End;
			#16 : Begin (*Q*)
							Modem.Remove;
              WriteLn ('Ending BBS.');
              BFiles.WriteAction2Log ('-SHOOTDOWN');
							Halt(0);
						End;
			#46 : Begin (*C*)
              SysOp.Shell (Config.Editor+' '+Config.CfgFile);
              BFiles.WriteAction2Log ('-LOCAL start of editing BBS.CFG');
              WriteLn ('Done.');
							ProcessKey:=FALSE;
							Exit;
						End;
			#47 : Local:=FALSE;
			Else ProcessKey:=FALSE;
		End;
	End	Else
		If Not(Ch=#27) Then ProcessKey:=FALSE;
End;


End.
