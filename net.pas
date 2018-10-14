Unit	Net;

INTERFACE

Const
	Chating : Boolean = FALSE;

Procedure Register 	(who: String);
Procedure SetWhere 	(where: String);
Procedure Who       (s: String);
Procedure SignOff;

Procedure SendTo (ToWho,what: String);
Procedure ReadSend;

Procedure Mesg (s: String);

Procedure ReadChat;
Procedure SetChat (make: Boolean);
Procedure Chat (what: String);

IMPLEMENTATION

Uses
	BFiles,
	DOS,
	Misc,
	Modem,
	Red;

Var
	NetPath,
	LegalName: String;

Procedure DefineName(Var who: String;setiraj: Boolean);
Var
	Len,
	Count : Byte;
Begin
	NetPath:=GetEnv('SONIC_BBS')+'\NET\';
	Len:=Ord(who[0]);
	If (Len>8) Then Begin
		who:=Copy(who,1,8);
		Len:=8;
	End;

	Count:=1;
	While Count<=Len do
		Case who[Count] Of
			'.' : who[Count]:='-';
			Else Inc(Count);
		End;
	If Setiraj Then LegalName:=NetPath+who;
End; {DefineUserAutoExec}

Procedure Register (who: String);
Var
	F: Text;
Begin
	DefineName (who,TRUE);
	Assign (F,NetPath+who+'.ON');  (* za online i who *)
	Rewrite (F);
	WriteLn (F,Misc.Username);
	WriteLn (F,Misc.Stat ('TI'));
	Close (F);

	Assign (F,NetPath+who+'.SND'); (* za send *)
	ReWrite (F);
	Close (F);
End;

Procedure SetWhere (where: String);
Var
	F: Text;
Begin
	Assign (F,LegalName+'.WHR'); (* gdje je gospodin *)
	ReWrite (F);
	WriteLn (F,where);
	Close (F);
End;


Function ShowWhere (ko: String): String;
Var
	F: Text;
	Line: String;
Begin
	ko:=Copy (ko,1,Pos ('.',ko)-1)+'.WHR';
	Assign (F,ko);
	Reset (F);
	ReadLn (F,Line);
	ShowWhere:=Line;
	Close (F);
End;

Function IsOnLine (who: String):Boolean;
Begin
	IsOnLine:=BFiles.FileExists (NetPath+who+'.ON');
End;


Procedure Who (s: String);
Var
	DirInfo: SearchRec;
	line: String;
	ch	: Char;
	F		:	Text;
Begin
	If Not(Red.CheckRed(s,'WHO.LOG')) Then Exit;

	Modem.OutLn (#13+#13+'Username       Logged     Where');
	Modem.OutLn ('========================================');
	FindFirst (NetPath+'*.ON',Archive,DirInfo);
	While DosError=0 do Begin
		Assign 	(F,NetPath+DirInfo.Name);
		Reset 	(F);
		ReadLn 	(F,line);
		Modem.Out (Misc.MakeBlanks(line));
		ReadLn 	(F,line);
		Modem.Out (line+'   ');
		Modem.OutLn (ShowWhere(NetPath+DirInfo.Name));
		Close		(F);
		FindNext (DirInfo);
	End;

	(*
		Podrska za Linux, ko je na Hostu
		Sa linuxa cron startuje update_for_dos_bbs
		koji , opet:), startuje w.bassman > /dos/disk/e/bbs/net/who.unx
		svakih 10minuta, treba vidjeti zasto sporo dolazi do dolazenja
		podataka iz linuxa do dos-a...(tj. zasto uopste ne dolazi do
		dos-a, ako sam u dosu cijelo vrijeme cron odradi svoje i sve
		ok zapise ali ovaj supak od dosemu-a ne konta da su pristigli
		novi podaci ... i tako sve dok ne predjem u neki linux tty pa
		ga tek dosemu registruje
	*)

		If Not(FileExists(NetPath+'WHO.UNX')) Then Begin
			Modem.OutLn (#10+'Sonic linux host is inactive.');
			Red.HandleRedirect;
			Exit;
		End;

		Modem.OutLn (#10+'Sonic linux host is active.');
		Assign (F,NetPath+'WHO.UNX');
		Reset(F);
		While Not(EOF(F)) do Begin
			Read (F,ch);
			If ch=#10 Then Modem.OutLn ('')
								Else Modem.Out (ch);
		End;
		Close (F);

	Red.HandleRedirect;
End;

Procedure SignOff;
Var
	F: Text;
Begin
	Assign (F,LegalName+'.ON');
	{$I-}
	Reset (F);
	Close (F);
	Erase (F);
	{$I+}

	Assign (F,LegalName+'.SND');
	{$I-}
	Reset (F);
	Close (F);
	Erase (F);
	{$I+}

	Assign (F,LegalName+'.WHR');
	{$I-}
	Reset (F);
	Close (F);
	Erase (F);
	{$I+}
End;

Procedure SendTo (ToWho,what: String);
Var
	orig: String;
	F:	Text;
Begin
	If (ToWho='') Or (what='') Then Exit;
	orig:=ToWho;
	DefineName (ToWho,FALSE);
	If Not(IsOnLine (ToWho)) Then Begin
		Modem.OutLn ('User '+Misc.Lower(orig)+' is not on bbs.');
		Exit;
	End;

	Assign (F,NetPath+ToWho+'.SND');
	Append (F);
	WriteLn (F,Misc.Username+' -> '+what);
	Close (F);
End;


Procedure ReadSend;
Var
	F: Text;
	Line: String;
	DirInfo: SearchRec;
Begin
	FindFirst (LegalName+'.SND',Archive,DirInfo);
	If DirInfo.Size=0 Then Exit;

	Assign (F,LegalName+'.SND');
	Reset (F);
	While Not(Eof(F)) Do Begin
		ReadLn (F,line);
		If Line<>'' Then Modem.OutLn (Line);
		Misc.Prompt;
	End;
	Reset (F);
	ReWrite(F);
	Close (F);
End;

Procedure Mesg (s: String);
Begin
	If s='' Then Begin
		Case Misc.MesgOff Of
			TRUE	:	Modem.OutLn ('Message off');
			FALSE : Modem.OutLn ('Message on');
		End;
		Exit;
	End;

	If (s='ON') Or (s='YES') Or (s='Y') Or (s='1') Then
	Begin
		Misc.MesgOff:=FALSE;
		Net.SetWhere ('Sonic');
	End
	Else If (s='OFF') Or (s='NO') Or (s='N') Or (s='0') Then
	Begin
		Misc.MesgOff:=TRUE;
		Net.SetWhere ('Message Off');
	End
	Else Modem.OutLn ('mesg: Unknown option');
End;

(*
	CHAT procedure
*)

Procedure ReadChat;
Var
	F: Text;
	Line: String;
	DirInfo: SearchRec;
Begin
	FindFirst (LegalName+'.CHT',Archive,DirInfo);
	If DirInfo.Size=0 Then Exit;

	Assign (F,LegalName+'.CHT');
	Reset (F);
	While Not(Eof(F)) Do Begin
		ReadLn (F,line);
		If Line<>'' Then Modem.OutLn (Line);
	End;
	Reset (F);
	ReWrite(F);
	Close (F);
End;

Procedure SetChat (make: Boolean);
Var
	F: Text;
Begin
	Case make of
		TRUE : Begin
							Assign (F,LegalName+'.CHT');
							ReWrite (F);
							Close (F);
							Chating:=TRUE;
							Misc.ChatPrompt:=TRUE;
							Net.Chat ('[User '+Misc.Username+' entering the chat]');
					 End;
		FALSE	:	Begin
							Assign (F,LegalName+'.CHT');
							Erase (F);
							Chating:=FALSE;
							Misc.ChatPrompt:=FALSE;
							Modem.OutLn ('[Leaving the chat]');
						End;
	End;
End;


Procedure Chat (what: String);

	Procedure ChatSend (towho,what: String);
	Var
		F:	Text;
	Begin
		Assign (F,NetPath+ToWho+'.CHT');
		Append (F);
		WriteLn (F,what);
		Close (F);
	End;
Const
	first	:	Boolean	=	TRUE;

Var
	DirInfo	:	SearchRec;
	temp    : String;
Begin
	temp:=Upper(what);
	If Not(Chating) Or (what='') Then Exit;
	If (temp='.EX') Or (temp='..') Or (temp='.EX') Or (temp='.EXIT') Then Begin
			Misc.ChatPrompt:=FALSE;
			Net.SetChat (FALSE);
			Net.SetWhere ('Sonic');
	End;

	FindFirst (NetPath+'*.CHT',Archive,DirInfo);
	While DosError=0 do Begin
		temp:=Copy (DirInfo.Name,1,Pos('.CHT',DirInfo.Name)-1);

		If Not(Chating) Then ChatSend (temp,'[User '+Misc.Username+' leaving chat]')
		Else If Not(temp=LegalName) Then ChatSend (temp,Misc.Username+' - '+what);

		FindNext (DirInfo);
	End;
	First:=FALSE;
End;


Begin

End.
