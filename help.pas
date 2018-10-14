{$F+,O+}

Unit 	Help;

INTERFACE

Var
	HelpFile : String;  (* gdje je commands.bhf (bbs help file) *)

Procedure On (what: String);


IMPLEMENTATION

Uses
	Modem;

Var
	F	:	TEXT;
	Line: String;

Function Upper (s : String) : String;
Var
	i : Integer;
	d : Byte;
Begin
	d:=Ord(s[0]);
	For i:= 1 To d Do
		s[i]:=UpCase(s[i]);
	Upper:=s;
End; {F||Upper : String}

Function Open_BHF	: Boolean;
Begin
	Assign (F,HelpFile);
	{$I-}
	Reset (F);
	{$I+}
	If IOResult<>0 Then Begin
		Modem.OutLn ('BBS Help File does not exist.');
		Open_BHF:=FALSE;
	End
		Else Open_BHF:=TRUE;
End; {F|Open_BHF}

Function Found (what: String) : Boolean;
Begin
	While Not(EOF(F)) do begin
		ReadLn (F,Line);
		If Pos(what,Line)=1 Then Begin
			ReadLn (F,Line);
			Found:=TRUE;
			Exit;
		End;
	End;
	Found:=FALSE;
End; {F|Found : Boolean}


Procedure On (what: String);
Begin
	what:='['+Upper(what)+']';

  If Not(Open_BHF) Then Exit;
	If Not(Found(what)) Then Exit;

	While (Pos('[EOD]',Line)<>1) XOR Eof(F) do begin
		Modem.OutLn (Line);
		ReadLn (F,Line);
	End;

	Close (F);
End;

End.