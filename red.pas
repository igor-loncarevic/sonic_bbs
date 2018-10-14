{$F+,O+}

Unit	Red;

INTERFACE

Const
	Redirect : Boolean = FALSE;

Var
	RedirectFile: String;

Procedure OpenRedFile;
Procedure CloseRedFile;
Procedure Wr (s: String);
Procedure Take (var s: string);
Function CheckRed (s,name: String): Boolean;
Procedure HandleSign (Var s: String);
Procedure HandleRedirect;

IMPLEMENTATION

Uses
	Modem,
	Pad;

Var
	PadFileName	 : String;
	RED_FILE		 : Text;

Procedure Take (var s: string);
Begin
	While Pos(' ',s)>0 do
		Delete(s,1,1);
End;

Procedure OpenRedFile;
Begin
	Assign (RED_FILE,RedirectFile);
	{$I-}
	Reset (RED_FILE);
	{$I+}
	If IOResult<>0 	Then ReWrite (RED_FILE)
									Else Append (RED_FILE);
End;

Procedure CloseRedFile;
Begin
	Close (RED_FILE);
End;

Procedure Wr (s: String);
Begin
	Write (RED_FILE,s);
End;

Function CheckRed (s,name: String): Boolean;
Var
	Poz,
	Len	: Byte;
	F		: Text;
Begin
	Poz:=Pos('>',s);
	Len:=Ord(s[0]);
	If (s<>'') And (Poz=Len) Then Begin
		PadFileName:=name;
		RedirectFile:=Pad.PadRootDir+Pad.UserDir+'\'+PadFileName;
		Redirect:=TRUE;
		OpenRedFile;
		CheckRed:=TRUE;
	End
	Else If (Poz>0) And (Poz<Len) Then begin
		PadFileName:=Copy(s,poz+1,Len);

		If (Pos('\',PadFileName)>0) Or (Pos(':',PadFileName)>0) Then Begin
			Modem.OutLn ('Bad filename.');
			CheckRed:=FALSE;
			Exit;
		End;

		Take (PadFileName);

		Assign (F,'\'+PadFileName);      (* Staviti umesto \ temp direktory *)
		{$I-}
		ReWrite (F);
		Reset (F);
		{$I+}

		If IOResult<>0 Then Begin
			Modem.OutLn ('Bad filename.');
			CheckRed:=FALSE;
			Exit;
		End Else Begin
			Close (F);
			Erase (F);
			RedirectFile:=Pad.PadRootDir+Pad.UserDir+'\'+PadFileName;
			Redirect:=TRUE;
			OpenRedFile;
			CheckRed:=TRUE;
		End;
	End;
	CheckRed:=TRUE;
End;

Procedure HandleRedirect;
Begin
	If Redirect Then CloseRedFile; (* ako je bila redirekcija *)
	Redirect:=FALSE;
End;

Procedure HandleSign (Var s: String);
Var	poz: Byte;
Begin
	If Red.Redirect Then Begin
		poz:=Pos('>',s);
		s:=Copy(s,1,poz-1);
		Red.Take(s);
	End;
End; (* Za s+options gleda jel red i brise >, menja u potrebno *)



End.