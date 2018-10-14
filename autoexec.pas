{$O+,F+}

Unit	AutoExec;

INTERFACE

Const
	Viewing=1;
	Tracing=2;
	Running=3;

Var
	UserName,
	AutoExecPath : String;

Procedure Start (svakome,mode: Byte;s: String);
Procedure AutoExecModeParser (s,rest,options: String);


IMPLEMENTATION

Uses
	ANSI,
	BEditor,
	BFiles,
	Misc,
	Modem,
	Net,
	Help,
	SysOp;

Var
	UserAutoExec,
	TotalName 		: String;

Procedure DefineUserAutoExec;
Var
	Len,
	Count : Byte;
Begin
	Len:=Ord(UserName[0]);
	If (Len>8) Then Begin
		UserName:=Copy(UserName,1,8);
		Len:=8;
	End;

	Count:=1;
	While Count<=Len do
		Case UserName[Count] Of
			'.' : UserName[Count]:='-';
			Else Inc(Count);
		End;

	UserAutoExec:=UserName;
End; {DefineUserAutoExec}

Function BBFExist (s: String): Boolean;
Begin
	If FileExists(TotalName) Then BBFExist:=TRUE
	Else Begin
		Modem.Out (s);
		BBFExist:=FALSE;
	End;
End;


Procedure Start (svakome,mode: Byte;s: String);
Var
	OldDir,
	Line  		:	String;
	F         : Text;
Begin
	If Misc.ToHelp(s) Then Begin
		Case mode of
			Viewing : Help.On ('AUTOEXEC VIEW');
			Tracing : Help.On ('AUTOEXEC TRACE');
			Running : Help.On ('AUTOEXEC RUN');
		End;
		Exit;
	End;

	DefineUserAutoExec;		(* izvrsi potrebne konverzije*)
	If Svakome=1 	Then TotalName:=AutoExecPath+'TOALL.BBF' (* BBS Batch File *)
								Else TotalName:=AutoExecPath+UserAutoExec+'.BBF';

	If Not(BBFExist ('')) Then Exit;

	Assign (F,TotalName);
	Reset (F);
	While Not(Eof(F)) do Begin
		ReadLn (F,Line);
		If (Pos('AUTO',Misc.Upper(Line))>0) And Not(mode=Viewing) Then Begin
			Modem.OutLn (Enter+'You can''t have '+ANSI.BRIGHT+'AUTOexec directive'+ANSI.NORMAL+' in your Autoexec.');
			Close (F);
			Exit;
		End;
		Case mode Of
			Viewing : Modem.OutLn ('> '+Line);
			Tracing : If Not((Line='')) Then Begin
									Modem.Out ('Press Enter for ['+ANSI.BRIGHT+Line+ANSI.NORMAL+'] command.');
									Modem.TakeCommand(Not(Misc.MesgOff));
									Modem.Out (Enter);
									If Pos('!',Line)<>1 Then Line:='!'+Line;
									Misc.Parser (Line);
								End;
			Running : Begin
									If Pos('!',Line)<>1 Then Line:='!'+Line;
									Misc.Parser (Line);
								End;
		End; {Case}
	End;
	Close (F);
End; {Start}


Procedure Clear (s: String);
Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('AUTOEXEC DELETE');
		Exit;
	End;

	If Not(BBFExist ('You don''t have AUTOEXEC.')) Then Exit;

	If Not(Modem.Rest ('Are you sure you want to delete AutoExec')) Then Exit;
	BFiles.DeleteFile (TotalName);
	Modem.OutLn ('Deleted Batch File.');
End;


Procedure Edit;                                                               
Begin
	Autoexec.Start (0,Viewing,'');
(*	If Modem.Local Then SysOp.Shell ('q '+TotalName)
		Else  *)
		BEditor.Edit (TotalName);
End;


Procedure AutoExecModeParser (s,rest,options: String);
Begin
	If (s='?') Or (s='HELP') Then BFiles.Show (BFiles.AutoExecHelpFile)
	else if (s='CLS')   Then Misc.CLS (rest)
	else if (s='EDIT')  Then AutoExec.Edit
	else if (s='RUN')   Then AutoExec.Start (0,Running,rest+options)
	else if (s='TRACE') Then AutoExec.Start (0,Tracing,rest+options)
	else if (s='DELETE') Or (s='DEL') Then AutoExec.Clear (rest+options)
	else if (s='VIEW') Or (s='VI') Or (s='DIR') Then AutoExec.Start (0,Viewing,rest+options)
	else if (s='EX') Or (s='..') Or (s='EXIT') Or (s='\') Then
	Begin
		Misc.AutoExecPrompt:=FALSE;
		Net.SetWhere ('Sonic');
	End
	else If (s<>'') Then Modem.OutLn ('Unknown AutoExec command "'+s+'", type ? for Help');
End;

End.