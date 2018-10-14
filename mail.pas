{$O+,F+}

Unit 	Mail;

INTERFACE

Var
	Username,
	MailBase,
	MailMessages,
	Editor,
	LocalEditFile : String;

	NumberOfMails,							(* broj novih poruka 					*)
	FirstToRead,                (* prvi mail za citanje 			*)
	SearchFrom  	: LongInt;    (* prvi primljeni uopste mail *)

	NewMail,				  					(* imali novih poruka 				*)
	Region				: Boolean;    (* true za zadati region /A 	*)


Procedure Create_Dbf;
Procedure Close_Dbf;
Procedure Make_Dbf;
Function FindMail: Boolean;
Procedure MailModeParser (s,rest,options : String);
Procedure MakeNewMail;
Procedure ToNew (s: String);

Procedure Make10Mails (s: String); (* delirati *)
Procedure DisplayMailBase;

IMPLEMENTATION

Uses
	ANSI,
	BBSBase,
	BigBase,
	BEditor,
	BFiles,
	DbDate,
	Help,
	Misc,
	Modem,
	Net,
	Pad,
	Red,
	SysOp,
	TBase;

Var
	Dbf_File : DataObject;

Procedure Create_Dbf;
Begin
	CreateDbFile (MailBase);
	New (Dbf_File,Init (MailBase));
End;

Procedure Open_Dbf;
Begin
	New( Dbf_File, Init(MailBase));
End;

Procedure Close_Dbf;
Begin
	Dispose (Dbf_File,Done);
End;

Procedure Make_Dbf;
Begin
	With Dbf_File^ do begin
		ChangeField('NewField',
							'NUMBER' 		,'N',6,0 );
		AddField ('FROM'   		,'C',15,0);
		AddField ('TO'     		,'C',15,0);
		AddField ('SUBJECT'		,'C',50,0);
		AddField ('BINARY' 		,'C',12,0);
		AddField ('DATE'  		,'D', 0,0);
		AddField ('TIME'   		,'C', 8,0);
		AddField ('LINES'  		,'N', 3,0);
		AddField ('READED' 		,'N', 1,0);
		AddField ('REPLAY'    ,'N', 6,0);
		AddField ('SUMLINES'  ,'N', 7,0);
		AddField ('READEDFROM','N', 1,0);
	End;
End;

Function MessageNumber : Real;  (* Vraca broj broj recordsa + 1 *)
Var	TotalMessages : LongInt;
Begin
	With Dbf_File^ do
		TotalMessages:=RecCount;
	Inc (TotalMessages);
	MessageNumber:=TotalMessages;
End;

Procedure MakeMail (towho,subject : String; reply : Real);
Var DateField 	: String;
		TimeString 	:	String;
		SysDate			: Date;
Begin
	towho:=Misc.Lower (towho);
	DbDate.Today (SysDate);
	DateField := DbDate.DateToFormat (SysDate);
	TimeString:= Misc.Stat ('TIME');
	With Dbf_File^ do begin
			ReplNum ('NUMBER' ,MessageNumber);
			Replace ('FROM'   ,Username);
			Replace ('TO'	   , towho);
			Replace ('DATE'   ,DateField);
			Replace ('TIME'   ,TimeString);
			Replace ('SUBJECT',subject);
			Replace ('BINARY' ,'~~~');
			Replace ('LINES'  ,'0');   (* Kako cu da znam koliko ce imati linija*)
			Replace ('READED' ,'0');   (* 0 - False , 1 - True *)
			ReplNum ('REPLAY'    ,Reply);
			Replace ('SUMLINES'	 ,'1');
			Replace ('READEDFROM','0');
			AddDbRec;
			Save;
	End;
End; {P|MakeUser}

Procedure OutPutMessage (rWhere,rLines : Real);
Var	F,
		FPad 		: Text;
		Where,
		Count,
		Lines : LongInt;
		Line	: String;
		Buffer: Array [1..4096] Of Char;
Begin
	SetTextBuf(F,Buffer); (* Bafer od 4k *)

	Assign (F,MailMessages);
	{$I-}
	Reset (F);
	{$I+}
	IF IOResult<>0 Then Begin
		BFiles.WriteAction2Log ('FATAL ERROR: MailMessages does not exist');
		WriteLn ('FATAL ERROR: MailMessages does not exist !!!');
		Exit;
	End;

	Where:=Trunc(rWhere);
	Lines:=Trunc(rLines);
	For Count:=1 To Where-1 Do
		ReadLn (F);

	For Count:=1 To Lines Do Begin
		ReadLn (F,Line);
		Modem.OutLn (Line)
	End;
	Close (F);
End;

Procedure SetLines (lines : Real);
Begin
	With Dbf_File^ do
		ReplNum ('LINES',lines);
End;

Procedure SetSumLines;
Var	rTotal : Real;
Begin
	With Dbf_File^ do begin
		If RecNo=1 Then Replace ('SUMLINES','2')
		Else Begin
			PrevRec;
			rTotal:=Add ('SUMLINES','LINES');
			rTotal:=rTotal+1;			(* Ovo plus 1 za kontrolne znakove *)
			NextRec;
			ReplNum ('SUMLINES',rTotal);
			Save;
		End;
	End; {With}
End; {P|SetSumLines}

Function Reduce (what: String;howmuch: Byte) : String; 
Var i,Len : byte;
Begin
	Len:=Ord(What[0]);
	If Len>howmuch 	Then Reduce:=Copy(what,1,howmuch)
									Else Reduce:=what;
End; (* Skracuje string na howmuch karaktera *)

Procedure Take (var s: string);
Begin
	While Pos(' ',s)>0 do
		Delete(s,1,1);
End; (* brise blanko znakove iz stringa *)


Function FindMail : Boolean;  (*Setuje broj prvog i ukupnog broja mail-ova*)
Var FirstMail	: LongInt;
		User			:	String;
		Gotovo,
		SetFirstMail: Boolean;

	Procedure CheckForFirstMail;
	Begin
		SetFirstMail:=TRUE;
		If (SearchFrom=0) And (NewMail) Then Begin
			BigBase.SetFirstMail (FirstMail);
			SearchFrom:=FirstMail;
		End;
	End;

	Procedure SetNewMailVars;
	Begin
		If Not(NewMail) Then FirstToRead:=Dbf_File^.RecNo; 	(* oznacava koju prvu*)
		NewMail:=TRUE;                              				(* da cita poruku    *)
		FirstMail:=Dbf_File^.RecNo;
		If firstmail=225 then Begin
				writeln ('Limit entered');
		end;
	End;

Begin
	SetFirstMail:=FALSE;
	Gotovo:=FALSE;
	NewMail:=FALSE;
	NumberOfMails:=0;
	User:=Misc.MakeBlanks(Username);
	SearchFrom:=BigBase.GetFirstMail;
	Open_dbf;
	With Dbf_File^ Do Begin
		If SearchFrom=0 Then GoTop    (* Pozicionira na prvu primljenu poruku *)
										Else GetDbRec (SearchFrom);

		Repeat
			If DbEof Then Gotovo:=True;
			If (FieldData('TO')=User) And (FieldData('READED')='0') Then Begin
					Inc (NumberOfMails);                     (* broj mailova *)
					SetNewMailVars;
			End;
			If (FieldData('FROM')=User) And (FieldData('READEDFROM')='0') Then
					SetNewMailVars;
			If (Not(SetFirstMail)) And (SearchFrom=0) Then Begin
				Close_Dbf;
				CheckForFirstMail;
				Open_Dbf;
			End;


			NextRec;
		Until Gotovo;
	End; {With}
	Close_Dbf;

	If NewMail	Then FindMail:=TRUE
							Else FindMail:=FALSE;
(*	CheckForFirstMail; *)
End; (* FindMail *)


Procedure GoToFirstMail;  (* Ide do prve poruke *)
Begin
	With Dbf_File^ do
		GetDbRec (FirstToRead);
End;

Procedure WriteMailListHeader;
Begin
	If Not(Red.Redirect) Then Modem.Out (ANSI.BRIGHT);

	Modem.OutLn ('Number  From         To        Date   Subject               #   File');
	If Not(Red.Redirect) Then Modem.Out (ANSI.NORMAL);
	Modem.OutLn ('===============================================================================');
End;

Procedure WriteMailList;  (* mail list commanda, izlistava mailove *)
Var Line : String[80];
		DateTemp : String[10];
Begin
	With Dbf_File^ do begin
		DateTemp:=Reduce(FieldData('DATE'),5);
		DateTemp[3]:='.';
		Line:=FieldData('NUMBER')+'. '+Reduce(FieldData('FROM'),10)+'-> ';
		Line:=Line+Reduce(FieldData('TO'),10)+DateTemp+'  ';
		Line:=Line+Reduce(FieldData('SUBJECT'),21);
		If Deleted Then Line:=Line+' DEL '
		Else If (FieldData('READED')='1') Then Line:=Line+' Yes '
																			Else Line:=Line+' No  ';
		If Pos ('~~~',FieldData('BINARY'))<>1 Then Line:=Line+FieldData('BINARY');
	End; {With}
	Modem.OutLn (Line);
End; {P|WriteMailList}

Function TakeFrom (s : String) : LongInt;
Var	temp 			  : String;
		MinusPos,
		Len,
		Count       : Byte;
		Code				: Integer;
		From				: LongInt;
Begin
	MinusPos:=Pos('-',s);
	If MinusPos>0 Then Begin
		temp:=Copy(s,1,MinusPos-1);    (* li 1234- =li 1234 *)
		Len:=Ord(temp[0]);
		Count:=1;
		While (Count<Len) And Not(Region) Do Begin
			If temp[Count] In ['0'..'9'] Then Begin
				Temp:=Copy(Temp,Count,Len);
				Region:=TRUE;
				Val (Temp,From,Code);
				If Code<>0 Then Begin
					Modem.OutLn ('Invalid number.');
					Region:=FALSE;
					Exit;
				End;
			End Else Inc(Count);
		End; {While}
	End; {if}
	If Region Then TakeFrom:=From
						Else TakeFrom:=0;
End; {F||TakeFrom : LongInt}

Procedure MailList (s : String);
Var	User					: String;
		All,
		ShowedHeader,
		Gotovo			 	: Boolean;
		From					: LongInt;
		Poz,Len				: Byte;
		F							: Text;

	Procedure _ShowHeader;
	Begin
		If Not(ShowedHeader) Then Begin
			WriteMailListHeader;
			ShowedHeader:=TRUE;
		End;
	End;

Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Mail List');
		Exit;
	End;

	Region:=FALSE;
	Gotovo:=FALSE;
	Open_Dbf;
	If Pos('/A',s)>0 Then All:=TRUE     (* lista sve poruke *)
									 Else All:=FALSE;
	From:=TakeFrom(s);
	With Dbf_File^ do    (* ako je x>od broja slogova > ciao *)
		If (From>RecCount) Then Begin
			Modem.OutLn ('Invalid number.');
			Close_Dbf;
			Exit;
		End;

	If Not(CheckRed (s,'MAILLIST.LOG')) Then Begin
		Close_Dbf;
		Exit;
	End;

	ShowedHeader:=FALSE;
	(*
	If (NewMail) and Not(Region) Then Begin
		WriteMailListHeader;
		GoToFirstMail;
		WriteMailList;
		ShowedHeader:=TRUE;
		NewMail:=FALSE;
	End;
	*)
	If (From>0) And (From>=SearchFrom)
		Then With Dbf_File^ Do
					GetDbRec (From)
		Else With Dbf_File^ Do
					GetDbRec (SearchFrom);

	User:=MakeBlanks(Username);
	With Dbf_File^ do begin
		Repeat
			If DbEof Then Gotovo:=TRUE;
			If (FieldData('TO')=User) Or (FieldData('FROM')=User) Then Begin
				If All Then Begin
					_ShowHeader;
					WriteMailList;
				End;

				If Not(All) And (FieldData('READEDFROM')='0')	And (User=FieldData('FROM')) And Not(Deleted) Then Begin
					_ShowHeader;
					WriteMailList;
				End;
				If Not(All) And (FieldData('READED')='0')	And (User=FieldData('TO')) And Not(Deleted) Then Begin
					_ShowHeader;
					WriteMailList;
				End;
			End;
			NextRec;
		Until Gotovo;
	End;
	Close_dbf;
	HandleRedirect;
End;


Procedure WriteHeader;
Const BeginLine = '================================'; (* 32 Hobbiton *)
			EndLine   = '--------------------------------';

Var DateField,
		TimeString,
		From,
		TTo,
		Subject,
		Number,
		lines,
		ReplyStr,
		Binary,
		line1,
		line2,
		line3,
		line4,
		line5	: String;
		reply	: real;
		Count	: Byte;
		F			: Text;
		Attached : Boolean;
Begin
	Attached:=False;
	With Dbf_File^ do begin
		DateField  := FieldData ('DATE');
		TimeString := FieldData ('TIME');
		From			 := FieldData ('FROM');
		TTo				 := FieldData ('TO');
		Subject		 := FieldData ('SUBJECT');
		Number		 := FieldData ('NUMBER');
		Lines			 := FieldData ('LINES');
		Reply			 := Increment ('REPLAY',0);
		Binary		 := FieldData ('BINARY');
	End;

	While Lines[1]=' ' do
		Lines:=Copy(lines,2,Ord(Lines[0]));

	If Not(Pos('~~~',Binary)>0) Then Attached:=True;

	DateField[3]:='-';
	DateField[6]:='-';

	TimeString:=Copy(TimeString,1,5);

	Take (Number); (* brise blanko znakove iz broja mail-a *)

	Str (Trunc(Reply),ReplyStr);

	line1:=' private:'+Number;
	If Reply>0 Then line1:=line1+',  Reply To: private:'+ReplyStr;
	line2:=' From:    '+From+'   '+DateField+' '+TimeString+'  '+Lines+' line(s)';
	line3:=' To:      '+TTo;
	line4:=' Subject: '+Subject;
	If Attached Then line5:=' Binary:  '+Binary;

	Modem.OutLn (BeginLine);  (* ispis zaglavlja poruke *)
	Modem.OutLn (line1);
	Modem.OutLn (line2);
	Modem.OutLn (line3);
	Modem.OutLn (line4);
	If Attached Then Modem.OutLn (line5);
	Modem.OutLn (EndLine);
End;

Procedure ReadMail;
Var rSum,
		rLines : Real;
		F			 : Text;
Begin
	With Dbf_File^ do begin
		If Deleted Then Exit;
		rSum:=Increment ('SUMLINES',0);
		rLines:=Increment ('LINES',0);
		If FieldData('FROM')=MakeBlanks(Username)
			Then Replace ('READEDFROM','1')
			Else Replace ('READED','1');
		Save;
	End;
	If Not(Redirect) Then Modem.Out (ANSI.BRIGHT);
	WriteHeader;
	If Not(Redirect) Then Modem.Out (ANSI.NORMAL);
	OutPutMessage (rSum,rLines);
	Modem.OutLn ('--------------------------------')
End; {P|ReadMail}

Procedure PressEnter;
Begin
	Modem.Out ('Press '+ANSI.BRIGHT+'Enter'+ANSI.NORMAL+' for next message.');
	Modem.TakeCommand (FALSE);
	Modem.OutLn (ANSI.CLS);
End;

Procedure MailRead (s,options: String);
Var	User	: String;
		All,
		Gotovo: Boolean;
		From	: LongInt;
		Poz,
		Len		: Byte;
		F			: File;
Begin
	If Misc.ToHelp(s+options) Then Begin
		Help.On ('Mail Read');
		Exit;
	End;

	Net.SetWhere ('Mail Read');
	FindMail;
	Region:=FALSE;
	Gotovo:=FALSE;
	If Pos('/A',s+options)>0 	Then All:=TRUE     (* lista sve poruke *)
														Else All:=FALSE;
	From:=TakeFrom(s+options);

	Open_Dbf;
	With Dbf_File^ do    (* ako je x>od broja slogova > ciao *)
		If (From>RecCount) Then Begin
			Modem.OutLn ('Invalid number.');
			Close_Dbf;
			Exit;
		End;

	If Not(CheckRed (s+options,'SESSION.LOG')) Then Begin
		Close_Dbf;
		Exit;
	End;

	If (NewMail) and Not(Region)Then Begin
		GoToFirstMail;
		ReadMail;
		NewMail:=FALSE;
	End;

	If (From>0) And (From>=SearchFrom)
		Then With Dbf_File^ Do
					GetDbRec (From)
		Else With Dbf_File^ Do
					GetDbRec (SearchFrom);
	If (From=0) And (SearchFrom=0) Then Dbf_File^.GoTop;

	User:=MakeBlanks(Username);
	With Dbf_File^ do begin
		Repeat
			If DbEof Then Gotovo:=TRUE;
			If ((FieldData('TO')=User) Or (FieldData('FROM')=User)) And Not(Deleted) Then Begin
				If All Then Begin
					If Not(Red.Redirect) Then PressEnter;
					ReadMail;
				End;
				If Not(All) And (FieldData('FROM')=User) And (FieldData('READEDFROM')='0') Then Begin
					If Not(Red.Redirect) Then PressEnter;
					ReadMail;
				End;
				If Not(All) And (FieldData('TO')=User) And (FieldData('READED')='0') Then Begin
					If Not(Red.Redirect) Then PressEnter;
					ReadMail;
				End;
			End;
			NextRec;
		Until Gotovo;
	End;
	Close_dbf;
	HandleRedirect;
	Net.SetWhere ('Sonic');
End; {P|MailRead}

Function TakeLocalMail (var abort: Boolean): Real;
Var F 		: Text;
		Count : Integer;
		temp	: Boolean;
Begin
	abort:=FALSE;
	If (Modem.Local) And (Pad.Parsing=FALSE) Then Begin (* local: ucitava editor,pita za slanje*)
			abort:=Not(Misc.Execute ('/C '+Editor+' '+LocalEditFile));
			If abort Then Exit;
			abort:=Not(Modem.Rest ('Send message'));
	End Else abort:=Not(BEditor.Edit (LocalEditFile)); (* remote *)

	{$I-}
	Assign (F,LocalEditFile);
	Reset (F);
	{$I+}
	If IOResult<>0 Then Begin
		ReWrite(F);
		Reset(F);
	End;
	Count:=0;
	While Not(EOF(F)) do begin
		Inc (Count);
		ReadLn (F);
	End;
	Close (F);

	TakeLocalMail:=Count; (* Koliko linija ima napisana poruka *)
End; {F||TakeLocalMail : Real}

Procedure SaveMailToBase (new: Boolean);
Var F_Mail,
		F_ToAdd : Text;
		Line		:	String;
Begin
	Assign (F_Mail,MailMessages);     (* otvara file za dodavanje *)
	Append (F_Mail);
	If new Then Assign (F_ToAdd,'e:\bbs\texts\welcome.bbs')
				 Else Assign (F_ToAdd,LocalEditFile);
	Reset (F_ToAdd);
	WriteLn (F_Mail,Trunc(MessageNumber)-1); (* kontrolni broj *)
	While Not(EOF(F_ToAdd)) Do Begin
		ReadLn  (F_ToAdd,Line);
		WriteLn (F_Mail,Line);
	End;
	Close (F_ToAdd);
	Close (F_Mail);
End; {P|SaveMailToBase}

Procedure MailSend (s : String);
Var Subject 	 : String;
		TotalLines : Real;
		abort			 : Boolean;
Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Mail Send');
		Exit;
	End;

	Net.SetWhere ('Mail Send');
	s:=Misc.Lower(s);
	BBSBase.Open_Dbf;
	If Not(BBSBase.IsUser (s)) Then Begin
		Modem.OutLn ('User don''t exist.');
		BBSBase.Close_Dbf;
		Exit;
	End;
	BBSBase.Close_Dbf;

	Open_Dbf;

	If Not(Pad.Parsing) Then Begin
		Modem.Out ('Subject: ');
		Subject:=Modem.TakeCommand (TRUE);
	End
	Else Subject:=Pad.GiveNextParLine;

	TotalLines:=TakeLocalMail (abort);

	If abort Then Begin
		Close_Dbf;
		Modem.OutLn ('Abort sending mail.');
		Exit;
	End;

	MakeMail (s,Subject,0);

	SetLines (TotalLines);
	SetSumLines;

	SaveMailToBase (FALSE);
	Str(Trunc(MessageNumber)-1, Subject);
	Modem.OutLn ('Mail number '+Subject+'.');
	Close_Dbf;

  BigBase.Open_Dbf;
	BigBase.IncrementField ('NO_MAIL');
	BigBase.Close_Dbf;

	Net.SetWhere ('Sonic');
End;

Procedure TakeBlankFromEnd (Var s:String);
Var Len: Byte;
Begin
	Len:=Ord(s[0]);
	If s[Len]=' ' Then s:=Copy(s,1,Len-1);
End;

Procedure MailReply (s : String);
Var Subject 	 : String;
		TotalLines : Real;
		ReplyTo		 : LongInt;
		Code			 : Integer;
		Len				 : Byte;
		abort			 : Boolean;
Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Mail Reply');
		Exit;
	End;

	Val (s,ReplyTo,Code);
	If Code<>0 Then Begin
		Modem.OutLn ('You must specifie number of message you want to reply.');
		Exit;
	End;

	Open_Dbf;
	With Dbf_File^ do begin
		GetDbRec (ReplyTo);
		Subject:=FieldData ('SUBJECT');
		s:=FieldData ('TO');
		If (s<>MakeBlanks(Username)) Or (Deleted) Then Begin
			Modem.OutLn ('You cannot reply on this message.');
			Close_Dbf;
			Exit;
		End;
		s:=FieldData ('FROM');
	End;

	If Not(Pos('Re: ',Subject)=1) Then Subject:='Re: '+Subject;


	TotalLines:=TakeLocalMail(abort);
	If abort Then Begin
		Close_Dbf;
		Modem.OutLn ('Replyed mail canceled.');
		Exit;
	End;
	MakeMail (s,Subject,ReplyTo);

	SetLines (TotalLines);
	SetSumLines;

	SaveMailToBase (FALSE);
	Str(Trunc(MessageNumber)-1, Subject);
	Modem.OutLn ('Mail number '+ANSI.BRIGHT+Subject+ANSI.NORMAL+'.');
	Close_Dbf;

  BigBase.Open_Dbf;
	BigBase.IncrementField ('NO_MAIL');
	BigBase.Close_Dbf;
End;

Procedure MailDelete (s:String);
Var 	DeleteNum : LongInt;
			Code : Integer;
Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Mail Delete');
		Exit;
	End;

	Val (s,DeleteNum,Code);
	If Code<>0 Then Begin
		Modem.OutLn ('You must specifie number of message you want to reply.');
		Exit;
	End;

	Open_Dbf;
	With Dbf_File^ do begin
		GetDbRec (DeleteNum);
		s:=FieldData ('FROM');
		If s<>MakeBlanks(Username) Then Begin
			Modem.OutLn ('You cannot delete this message. It''s not yours.');
			Close_Dbf;
			Exit
		End
		Else If Deleted Then Begin
			Modem.OutLn ('This message is already deleted.');
			Close_Dbf;
			Exit;
		End Else Begin
			Modem.OutLn ('Deleting mail number '+ANSI.BRIGHT+FieldData('NUMBER')+ANSI.NORMAL+'.');
			DbDelete;
		End;
	End;
	Close_Dbf;
End; {P|MailDelete}

Procedure MailUnDelete (s:String);
Var 	DeleteNum : LongInt;
			Code : Integer;
Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Mail Undelete');
		Exit;
	End;

	Val (s,DeleteNum,Code);
	If (Code<>0) Then Begin
		Modem.OutLn ('Invalid number.');
		Exit;
	End;

	Open_Dbf;
	With Dbf_File^ do begin
		GetDbRec (DeleteNum);
		s:=FieldData ('FROM');
		If s<>MakeBlanks(Username) Then Begin
			Modem.OutLn ('You cannot undelete this message. (#'+FieldData('NUMBER')+')');
			Close_Dbf;
			Exit
		End
		Else If Not(Deleted) Then Begin
			Modem.OutLn ('This message is not deleted. (#'+FieldData('NUMBER')+')');
			Close_Dbf;
			Exit;
		End Else Begin
			Modem.OutLn ('Undeleting mail number '+ANSI.BRIGHT+FieldData('NUMBER')+ANSI.NORMAL+'.');
			Recall;
		End;
	End;
	Close_Dbf;
End; {P|MailDelete}

Procedure MailAttach (sNumber,filename: String);
Var
	Code  : Integer;
	Number: LongInt;
Begin
	If Misc.ToHelp(sNumber+filename) Then Begin
		Help.On ('Mail Attach');
		Exit;
	End;

	Val (sNumber,Number,Code);
	If (Code<>0) Then Begin
		Modem.OutLn ('Invalid number.');
		Exit;
	End;
	If FileName='' Then Begin
		Modem.OutLn ('Missing filename.');
		Exit;
	End;
	If Not(Pad.PadFileExist(filename)) Then Begin
		Modem.OutLn ('Can''t find '+filename+' in Pad.');
		Exit;
	End;

	Open_Dbf;
	With Dbf_File^ do begin
		If Number>RecCount Then Begin
			Modem.OutLn ('That message don''t exist.');
			Close_Dbf;
			Exit;
		End;
		GetDbRec (Number);
		sNumber:=FieldData ('FROM');
		If (sNumber<>MakeBlanks(Username)) Or Deleted Then Begin
			Modem.OutLn ('Attach denied. (#'+FieldData('NUMBER')+')');
			Close_Dbf;
			Exit
		End;

		Replace ('BINARY',filename);

		Pad.CopyAttachedFile (filename);
	End;
	Close_Dbf;
End; {P:MailAttach}

Procedure TakeRight (var s:String);
Var
	len:byte absolute s;
Begin
	While s[len]=' ' do
		s:=Copy(s,1,len-1);
End;

Procedure MailUnAttach (s: String);
Var
	num	: LongInt;
	Code: Integer;
	name: String;
Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Mail Unattach');
		Exit;
	End;

	Val (s,Num,Code);
	If Code<>0 Then Begin
		Modem.OutLn ('Ivalid number.');
		Exit;
	End;

	Open_Dbf;
	With Dbf_File^ do begin
		GetDbRec (Num);
		s:=FieldData ('FROM');
		If s<>MakeBlanks(Username) Then Begin
			Modem.OutLn ('It''s not yours message.');
			Close_Dbf;
			Exit
		End
		Else If Deleted Then Begin
			Modem.OutLn ('This message is deleted.');
			Close_Dbf;
			Exit;
		End
		Else If Pos('~~~',FieldData('BINARY'))>0 Then Begin
			Modem.OutLn ('This message is does not have attached file.');
			Close_Dbf;
			Exit;
		End Else Begin
			name:=FieldData('NUMBER');
			Take(name);
			Modem.OutLn ('Unattaching file from mail #'+ANSI.BRIGHT+name+ANSI.NORMAL+'.');

			name:=FieldData('BINARY');
			Replace ('BINARY','~~~');
			TakeRight (name);
			BFiles.DeleteFile (Pad.MailAttachDir+'\'+name);
		End;
	End;
	Close_Dbf;
End; {P|MailUnAttach}

Procedure Download (s: String);
Var
	num	: LongInt;
	Code: Integer;
	name: String;
Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Mail.Download');
		Exit;
	End;

	Val (s,Num,Code);

	Open_Dbf;
	With Dbf_File^ do begin
		If (Code<>0) Or (Code>RecCount) Then Begin
			Modem.OutLn ('Ivalid number.');
			Close_Dbf;
			Exit;
		End;

		GetDbRec (Num);
		s:=FieldData ('TO');
		If s<>MakeBlanks(Username) Then Begin
			Modem.OutLn ('You''r not allowed for downloading file from this message.');
			Close_Dbf;
			Exit
		End
		Else If Deleted Then Begin
			Modem.OutLn ('This message is deleted.');
			Close_Dbf;
			Exit;
		End
		Else If Pos('~~~',FieldData('BINARY'))>0 Then Begin
			Modem.OutLn ('This message is does not have attached file.');
			Close_Dbf;
			Exit;
		End Else Begin
			name:=FieldData('BINARY');
			TakeRight (name);
			BFiles.Upload (Pad.MailAttachDir+'\'+name);
		End;
	End;
	Close_Dbf;
End; {P|MailUnAttach}


Procedure MakeNewMail;
Var
	F : Text;
	temp: String;
Begin
	Modem.Out ('Password for command: ');
	Modem.Hide:=TRUE;
	temp:=Modem.TakeCommand (FALSE);
	Modem.Hide:=FALSE;
	If Not(temp='SuicidaL') Then Begin
		Modem.OutLn (Enter+'Wrong password, access denied.');
		BFiles.WriteAction2Log ('-NEW MAIL SYSTEM failed on password by '+Misc.Username+'['+temp+']');
		Exit;
	End;

	Mail.Create_Dbf;
	Mail.Make_Dbf;
	Mail.Close_Dbf;
	Assign (F,Mail.MailMessages);
	ReWrite (F);
	Close	(F);
	Modem.OutLn (Enter+#7+'Done.');
	BFiles.WriteAction2Log ('-NEW MAIL SYSTEM created by '+Misc.Username);
End;

Procedure ToNew (s: String);
Begin
	Open_Dbf;

	MakeMail (s,'Welcome',0);
	SetLines (19);
	SetSumLines;
	Close_Dbf;

	SaveMailToBase (TRUE);

	BigBase.Username:='topaz';
	BigBase.Open_Dbf;
	BigBase.IncrementField ('NO_MAIL');
	BigBase.Close_Dbf;
End;

Procedure Make10Mails (s: String);
Var
	i: Byte;
Begin
	i:=0;
	Repeat
		Inc (i);
		Open_Dbf;

		MakeMail (s,'Welcome',0);
		SetLines (19);
		SetSumLines;
		Close_Dbf;

		SaveMailToBase (TRUE);

		BigBase.Username:='anubis';
		BigBase.Open_Dbf;
		BigBase.IncrementField ('NO_MAIL');
		BigBase.Close_Dbf;
	Until Not(i<10);
End;

Procedure DisplayMailBase;
Begin
	Open_Dbf;
	Dbf_File^.DisplayFields;
	Close_Dbf;
End;


Procedure MailModeParser (s,rest,options : String);
Begin
	If (s='CLS')  Then Misc.CLS (rest)
	else if (s='SE') 		Or (s='SEND') 		Then Mail.MailSend 			(rest)
	else if (s='RE')  	Or (s='READ') 		Then Mail.MailRead  		(rest,options)
	else if (s='UNDEL') Or (s='UNDELETE') Then Mail.MailUnDelete	(rest)
	else if (s='AT')    Or (s='ATTACH')   Then Mail.MailAttach 	 	(rest,options)
	else if (s='UNAT')  Or (s='UNATTACH') Then Mail.MailUnAttach 	(rest)
	else if (s='?') 		Or (s='HELP')			Then BFiles.Show (BFiles.MailHelpFile)
	else if (s='DO')		Or (s='DOWNLOAD') Then Mail.Download      (rest)
	else if (s='LI')  	Or (s='LIST')  	Or (s='DIR')	Then Mail.MailList 	(rest)
	else if (s='REP') 	Or (s='REPLY') 	Or (s='ANS') Or (s='ANSWER')	Then Mail.MailReply (rest)
	else if (s='DEL') 	Or (s='DELETE') Or (s='ERASE')	Then Mail.MailDelete(rest)
	else if (s='EX') 		Or (s='..') Or (s='EXIT') Or (s='\') Then
	Begin
		SetMailMode (FALSE);
		Net.SetWhere ('Sonic');
	End
	else if s<>'' Then Modem.OutLn ('Unknown Mail command "'+s+'", type ? for Help');
End; {P|MailModeParser}


End.
