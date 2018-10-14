{$O+,F+}

Unit	BEditor;

INTERFACE

Function Edit (filename: String): Boolean;   (* True - poslana poruka *)

IMPLEMENTATION

Uses
	ANSI,
	Help,
	Modem,
	Net,
	Pad;

Const
	HelpLine=ANSI.BRIGHT+'S'+ANSI.NORMAL+'ave, '+
					 ANSI.BRIGHT+'C'+ANSI.NORMAL+'ancel, '+
					 ANSI.BRIGHT+'H'+ANSI.NORMAL+'elp, '+
					 ANSI.BRIGHT+'Q'+ANSI.NORMAL+'uit? ';

	BeginLine=#13+#10+'   ====(.. for end)===========================================(72 chars)===';
	EndOfMessage='..\..ex\.exit\.quit\'+#3's\'+#4's\';

Var
	poruka: String;
	fname : Text;


Procedure Create (filename: String; totalcount: Word);
Begin
	Assign (fname,filename);
	ReWrite (fname);
	Append (fname);
End;

Function Menu : Boolean;
Var
	Temp:	String;
	Ch	:	Char;
Begin
	Repeat
		Modem.Out (#13+#10+HelpLine);
		Temp:=Modem.TakeCommand(FALSE);
		Ch:=Temp[1];
		Case UpCase(Ch) Of
			'C','Q' : Begin
									Menu:=FALSE;
									Exit;
								End;
			'S'			:	Begin
									Menu:=TRUE;
									Exit;
								End;
			'H'			: Help.On ('Editor');
		End;
	Until FALSE;
End;


Function Edit (filename: String): Boolean;
Var
	TotalLine: Integer;
	Line		 : String;
	Send,
	Quit		 : Boolean;
Begin
	Net.SetWhere ('Editor');
	Create (filename,TotalLine);
	Send:=FALSE;
	Quit:=FALSE;
	TotalLine:=1;
	Modem.Out (BeginLine);
	Repeat
		Str (TotalLine,Line);
		Modem.Out (#13+#10+ANSI.BRIGHT+Line+ANSI.NORMAL+': ');

		Case Pad.Parsing of
			FALSE :	poruka:=Modem.TakeCommand(FALSE);
			TRUE  : poruka:=Pad.GiveNextParLine;
		End;

		If (Pos(poruka+'\',EndOfMessage)>0) and (poruka<>'') Then
			If (poruka=#3's') Or (poruka=#4's') Then Send:=TRUE
				Else	Case Menu Of
								True : Send:=TRUE;
								False: Quit:=FALSE;
							End
			Else Begin
				If Pad.Parsing Then Modem.Out (poruka);
				WriteLn (fname,poruka);
				Inc (TotalLine);
			End;
	Until Send Or Quit;

	If Quit Then Begin
		Edit:=FALSE;
		Exit;
	End;

	Edit:=TRUE;
	Close (fname);
	Modem.Out (#13+#10);
	Net.SetWhere ('Sonic');
End;

End.






