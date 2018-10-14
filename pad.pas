{$O+,F+}

Unit 	Pad;

INTERFACE

Const
	Parsing : Boolean = FALSE;

Var
	PadRootDir,
	UserDir,
	Archiver,
	PadNumber,
	UserName,
	MailAttachDir : String;

	Dont : Boolean;

Function PadFileExist (Var filename: String): Boolean;

Procedure DefineUserDir;
Procedure Start;
Procedure Stop;
Function GiveNextParLine: String;
Procedure Parse (filename,options: String);
Procedure CopyAttachedFile (filename: String);
Procedure PadModeParser (s,rest,options: String);


IMPLEMENTATION

Uses
	ANSI,
	BFiles,
	BigBase,
	DOS,
	Help,
	Misc,
	Modem;

Var
	File4Parsing: Text;

Procedure DefineUserDir;
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

	UserDir:=UserName;
End; (* Pretvara username u prihvatljivi dir name *)


Function PadFileExist (Var filename: String): Boolean;
Var
	DirInfo : SearchRec;
Begin
	If Dont Then Exit;
	FindFirst (PadRootDir+UserDir+'\'+filename,ANYFILE-DIRECTORY,DirInfo);
	filename:=DirInfo.Name;
	If DosError=0 Then PadFileExist:=TRUE
								Else PadFileExist:=FALSE;
End; (* Da li postoji fajl u Pad-u *)


Function PadExist : Boolean;
Var
	BackDir	:	String;
	DirInfo : SearchRec;
Begin
	If Dont Then Exit;
	FindFirst (PadRootDir+UserDir,DIRECTORY,DirInfo);
	If DosError=0 Then PadExist:=TRUE
								Else PadExist:=FALSE;
End; (* Da li postoji Pad *)


Procedure Start;
Begin
	If Dont Then Exit;
	If Not(PadExist) Then MkDir (PadRootDir+UserDir)
		Else Modem.OutLn (Enter+'Your PAD is '+ANSI.BRIGHT+'not'+ANSI.NORMAL+' empty.');
End;


Procedure Stop;
Var
	DirInfo : SearchRec;
Begin
	If Dont Then Exit;
	FindFirst (PadRootDir+UserDir+'\*.*',ARCHIVE,DirInfo);
	If DosError=0 Then Modem.OutLn (Enter+'Your PAD will be '+ANSI.BRIGHT+'saved'+ANSI.NORMAL+' for next session.'+Enter)
								Else RmDir (PadRootDir+UserDir);
End;

Function InPad (s: String): Boolean;
Begin
		(* Zastita da ne iscita nesto van PADa *)
	If (Pos('..',s)>0) Or (Pos('\',s)>0) Or (Pos(':',s)>0) Or (Ord(s[0])>12) Then Begin
		Modem.OutLn ('Illegal parametar.');
		InPad:=FALSE;
		Exit;
	End;
	InPad:=TRUE;
End;

Procedure PadDir (s : String);
Var
	DirInfo : SearchRec;
	SumSize	:	LongInt;
	SumFiles: Byte;
	Size		: Boolean;
	Temp		:	String;

Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Dir');
		Exit;
	End;

	If Dont Then Exit;

	Size:=FALSE;
	If s='PAD.SHOW.SIZE' Then Begin
		s:='*.*';
		Size:=TRUE;
	End;

	If Not(InPad(s)) Then Exit;

	If (s='') Or (s='.') Then s:='*.*';

	DosError:=0;
	SumSize:=0;
	SumFiles:=0;

	FindFirst (PadRootDir+UserDir+'\'+s,ARCHIVE,DirInfo);
	While DosError=0 do begin
		If Not(Size) Then Begin
			Str (DirInfo.Size:7,s);
			s:='    '+MakeBlanks(Lower(DirInfo.Name))+'     '+s+' bytes.';
			Modem.OutLn (s);
		End; (* Za SIze naredbu *)
		Inc (SumSize,DirInfo.Size);
		Inc (SumFiles);
		FindNext (DirInfo);
	End;

	Str (SumSize,s);
	Str (SumFiles,temp);
	Modem.OutLn (Enter+'          '+s+' bytes in '+temp+' file(s).');
End; {PadDir}


Procedure PadDel (s: String);
Var
	BackDir : String;

Begin
	If (Misc.ToHelp(s)) Then Begin
		Help.On ('Delete');
		Exit;
	End;

	If Dont Or Not(InPad(s)) Then Exit;

	If (s='.') Then s:='*.*';

	If (s='*.*') And (Not(Modem.Rest ('Delete all files in PAD'))) Then Exit;

	GetDir (0,BackDir);
	ChDir (PadRootDir+UserDir);
	BFiles.DeleteFile (s);

	ChDir ('..');
	ChDir (BackDir);
End; {PadDel}


Procedure PadAV (s: String);
Var
	BackDir : String;

Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Archive View');
		Exit;
	End;

	If Dont Or Not(InPad(s)) Then Exit;

	If (s='.') Then s:='*.*';

	GetDir (0,BackDir);
	ChDir (PadRootDir+UserDir);

	BFiles.AV (s);

	ChDir ('..');
	ChDir (BackDir);
End; {PadDel}


Procedure PadType (s : String);
Var
	BackDir : String;

Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Type');
		Exit;
	End;

	If Dont Or Not(InPad(s)) Then Exit;
	If (s='.') Then s:='*.*';

	GetDir (0,BackDir);
	ChDir (PadRootDir+UserDir);

	BFiles.View (s);

	ChDir ('..');
	ChDir (BackDir);
End; {PadDel}


Procedure PadCompress (s: String);
Var
	BackDir,
	Temp		: String;
	Poz			: Byte;
	DirInfo : SearchRec;

Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Pad Compress');
		Exit;
	End;

	If Dont Or Not(InPad(s)) Then Exit;

	GetDir (0,BackDir);
	ChDir (PadRootDir+UserDir); (* staviti pad root + user pad *)

	BigBase.SetPadNumber;

	If (s='') Then s:='*.LOG'
	Else If (s='.') Then s:='*.*';

	FindFirst (s,ARCHIVE,DirInfo);
	If DosError<>0 Then Begin
		Modem.OutLn ('File(s) '+s+' does not exist in pad.');
		Exit;
	End;

	Modem.OutLn ('Processing '+s+' in PAD'+PadNumber);

  If Execute (' /C '+Archiver+' '+'PAD'+PadNumber+' '+s+' >nul') Then Modem.OutLn ('Ok')
    Else Modem.OutLn ('Error in compressing');

	If (s='*.LOG') Then PadDel (s); (* obrisi sve *.LOG zipovane fajlove *)

	ChDir ('..');
	ChDir (BackDir);

	BigBase.Open_Dbf;
	BigBase.IncrementField ('PAD_NO');
	BigBase.Close_Dbf;
End; {PadCompress}

Procedure PadRename (s: String);
Var
	BackDir,
	Temp		: String;
	Poz			: Byte;

Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Rename');
		Exit;
	End;

	If Dont Or Not(InPad(s)) Then Exit;

	GetDir (0,BackDir);
	ChDir (PadRootDir+UserDir); (* staviti pad root + user pad *)

	BFiles.RenameFile (s);

	ChDir ('..');
	ChDir (BackDir);
End; {PadRename}

Procedure CopyAttachedFile (filename: String);
Var
	BackDir: String;
Begin
	GetDir (0,BackDir);
	ChDir (PadRootDir+UserDir); (* staviti pad root + user pad *)

	BFiles.CopyFile (filename+' '+MailAttachDir+'\'+filename);
	Modem.OutLn ('Done.');

	ChDir ('..');
	ChDir (BackDir);
End; {CopyAttachedFile}

Function GiveNextParLine: String;
Var
	Line: String;
Begin
	{$I-}
	Readln (File4Parsing,Line);
	{$I+}
	If IOResult<>0 Then Begin
		Pad.Parsing:=FALSE;
		Close (File4Parsing);
	End
	Else GiveNextParLine:=Line;
End;

Procedure Parse (filename,options: String);
Var
	BackDir,
	Line		: String;
	Quite	: Boolean;
Begin
	GetDir (0,BackDir);
	ChDir (PadRootDir+UserDir); (* staviti pad root + user pad *)

	Quite:=FALSE;
	If (options='') and (filename='/Q') Then Begin
		filename:='PARSE.ME';
		Quite:=TRUE;
	End
	Else If Filename='' Then Filename:='PARSE.ME'
	Else If options='/q' Then Quite:=TRUE;
{$I-}
	Assign (File4Parsing,filename);
	Reset (File4Parsing);
{$I+}
	If IOResult<>0 Then Begin
		Modem.OutLn ('File '+filename+' does not exist.');
		Close (File4Parsing);
	End
	Else Begin
		Pad.Parsing:=TRUE;
{$I-}
		While Not(Eof(File4Parsing)) do Begin
			ReadLn (File4Parsing,Line);
			If Not(Quite) Then	Modem.OutLn (Line);
			Misc.Parser (Line);
		End;
		If Pad.Parsing Then	Close (File4Parsing);
		Pad.Parsing:=FALSE;
	End;
{$I+}

	ChDir ('..');
	ChDir (BackDir);
End; { Parse }



Procedure PadModeParser (s,rest,options: String);
Begin
	If (s='?') Or (s='HELP') Then BFiles.Show (BFiles.PadHelpFile)
	else if (s='CLS')  	Then Misc.CLS (rest)
	else If (s='CL')  Or (s='CLEAR') 	Then PadDel 	('*.*')
	else If (s='VI') 	Or (s='VIEW') 	Then PadAV 		(rest)
	else If (s='TY')  Or (s='TYPE')		Then PadType 	(rest)
	else If (s='DI') 	Or (s='DIR') 		Then PadDir 	(rest)
	else If (s='PAR') Or (s='PARSE')  Then Parse		(rest,options)
	else If (s='SI')  Or (s='SIZE')		Then PadDir		('PAD.SHOW.SIZE')
	else If (s='COM') Or (s='COMPRESS')Then PadCompress (rest)
	else If (s='REN') Or (s='RENAME')	 Then PadRename		(rest+' '+options)
	else If (s='DEL') Or (s='DELETE') Or (s='ERASE') 	Then PadDel 	(rest)
	else if (s='EX') 	Or (s='..') Or (s='EXIT') Or (s='\') Then Misc.PadPrompt:=FALSE
	else If (s<>'') Then Modem.OutLn ('Unknown Pad command "'+s+'", type ? for Help');
End; {PadModeParser}

End.
