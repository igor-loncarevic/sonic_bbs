{$F+,O+}

Unit 	BFiles;

INTERFACE

Const
	Log					:	Boolean = FALSE;
	SysOpRight 	: Byte = 128;
	FileAdmRight: Byte = 8;

Var
	ArcViewFile,
	DescribeFile,
	LogFile,
	TreeFile,
	NormalHelpFile,
	FileAdmHelpFile,
	SysOpHelpFile,
	MailHelpFile,
	PadHelpFile,
	AutoExecHelpFile,
	ResumeHelpFile,
	DoorList			   : String;

	Width : Integer;

Procedure Show 						(What: String);
Procedure ShowFiles 			(What: String);
Procedure AV 							(s: String);
Procedure Describe 				(s: String);
Procedure DeleteFile 			(s: String);
Procedure RenameFile 			(s: String);
Procedure CopyFile 				(s: String);
Procedure MakeDir 				(s: String);
Procedure RemoveDir 			(s: String);
Function FileExists 			(FileName: String): Boolean;

Procedure StartLog;
Procedure CloseLog;
Procedure MakeLog 				(s: String);
Procedure WriteAction2Log (s: String);

Procedure CD 							(Name: String);
Procedure Tree 						(s: String);
Procedure View 						(s: String);
Procedure Helping 				(s: String);

Procedure Upload (fname: String);   (* Download for user *)
Procedure Download (fname: String); (* Upload for user *)

IMPLEMENTATION

Uses
	ANSI,
	AutoExec,
	DOS,
	Help,
	Modem,
	Misc,
	Net,
	Pad,
	Red,
	SysOp;

Const
	OpenLog: Boolean = FALSE;

Var
	FLog	:	Text;

Procedure Show (What : String);
Var
	F 		: Text;
	Line 	: String;
	Ch 		: Char;
	Count : Byte;
Begin
	Assign (F,What);
	{$I-}
	Reset (F);
	{$I+}
	If IOResult<>0 Then Modem.OutLn ('Cannot access '+What+' file.')
		Else Begin
			If What=ArcViewFile Then ReadLn (F);

			Count:=1;
			While Not Eof(F) Do Begin
				Read (F,Ch);
				Case Ch Of
					#9 : Modem.Out ('  ');  (* TAB *)
					#13: Begin
								INC (Count);
								Modem.Out (#13);
							 End
					Else Modem.Out (Ch);
				End; {Case}

				If (Count=Width) And Not(Red.Redirect) Then Begin
					If Not(Modem.Rest ('Show rest')) Then Begin
						Close (F);
						Exit;
					End;
					Count:=1;
				End;
			End;
		Close (F);
	End;
End; {P|Show}

Procedure ShowFiles (What : String);
Var
	DirInfo : SearchRec;
	Temp		: String;
Begin
	FindFirst (What,Archive,DirInfo);
	While DosError=0 do Begin
		Show (DirInfo.Name);
		FindNext (DirInfo);
		If DosError<>0 Then Exit;
		Modem.OutLn (#13+#10+'Press '+ANSI.BRIGHT+'Enter'+ANSI.NORMAL+' for next file.');
		Temp:=Modem.TakeCommand(TRUE);
	End;
End; {P|ShowFiles}

Procedure AV (s : String); (* Archive view command *)
Begin
	If Misc.ToHelp(s) Or (s='') Then Begin
		Help.On ('Archive View');
		Exit;
	End;

	If Not(Red.CheckRed(s,'ARCVIEW.LOG')) Then Exit;
	Red.HandleSign (s);

	If Misc.Execute ('/C '+'FV '+s+' > '+ArcViewFile) (*ubaciti iz configa*)
			Then Show (ArcViewFile);
	Red.HandleRedirect;
End; { AV }

Function FileExists (FileName : String)	: Boolean;
Var f: file;
Begin
	{$I-}
	Assign(f, FileName);
	Reset(f);
	Close(f);
	{$I+}

	FileExists:=(IOResult = 0) and (FileName <> '');
End;  {F||FileExists : Boolean}



Procedure Describe (s : String);
Var
	F				 : Text;
	Descript,
	Line		 : String;
	DirInfo	 : SearchRec;

Begin
	If (s='') Or Misc.ToHelp(s) Then Begin
		Help.On ('Describe');
		Exit;
	End;

	FindFirst (s,DIRECTORY+ARCHIVE,DirInfo);

	If (DosError<>0) Then Begin  (* Postoji li file ili dir za descripciju *)
		Modem.OutLn ('File not found "'+s+'"');
		Exit;
	End;

	{$I-}
	Assign (F,DescribeFile);         (* Otvori file u kome se nalaze opisi *)
	Reset (F);
	{$I+}
	If IOResult<>0 Then Begin
		ReWrite (F); (* Ako ne postoji DESCRIPT.ION kreiraj *)
		Reset (F);
	End;

	While DosError=0 Do Begin

		Reset(F);
		Descript:='';

		While Not Eof(F) do begin
			ReadLn (F,Line);
			If Pos (Lower(DirInfo.Name),Line)=1 Then
				Descript:=Copy (Line,Ord(DirInfo.Name[0])+2,Ord(Line[0]));
		End;

		Modem.OutLn ('File: '+ANSI.BRIGHT+DirInfo.Name+ANSI.NORMAL);
		Modem.OutLn ('Old description: '+ANSI.BRIGHT+Descript+ANSI.NORMAL);
		Modem.Out   ('New description: ');
		Descript:=Modem.TakeCommand(FALSE);
		Modem.OutLn ('');

		If Not((Descript='')) Then Begin (* Ako je samo Enter, ne mjenja se *)
			Append (F);
			WriteLn (F,Lower(DirInfo.Name)+' '+Descript);
		End;

		FindNext (DirInfo);
	End; {While}
	Close (F);
End;

Procedure DeleteFile (s : String);
Const
	sCount  : String 	= '';
	sTotSize: String 	= '';
Var
	F				: File;
	DirInfo : SearchRec;
	Count		: Byte;
	TotSize : LongInt;

Begin
	If Misc.ToHelp(s) Or (s='') Then Help.On ('Delete')
	Else Begin
		If (Pos('*',s)>0) Or (Pos('?',s)>0) Then begin
			If Not(Modem.Rest('Delete '+s)) Then Exit;
			Count:=0;
			TotSize:=0;
			FindFirst (s,ARCHIVE,DirInfo);       (* sa jokerima *)
			While DosError=0 Do Begin
				Inc (TotSize,DirInfo.Size);
				Inc (Count);
				Assign(f, DirInfo.Name);
				Reset(f);
				Close(f);
				Modem.OutLn ('Deleting -> '+ANSI.BRIGHT+DirInfo.Name+ANSI.NORMAL);
				Erase(f);
				FindNext (DirInfo);
			End; {While}
			Str (Count,sCount);
			TotSize:=Round (TotSize/1024);
			Str (TotSize,sTotSize);
			Modem.Out ('      '+sCount+' file(s) deleted');
			If TotSize>0 Then Modem.OutLn (', '+ANSI.BRIGHT+sTotSize+ANSI.NORMAL+' kb freed.');
		End Else Begin			(* bez jokera *)
			Assign(f, s);
			{$I-}
			Reset(f);
			{$I+}
			If (IOResult<>0) And Not(Pos(Pad.MailAttachDir,s)>0) Then	Modem.OutLn('Cannot find '+s+'.')
			Else Begin
				Close(f);
				If Not(Pos(Pad.MailAttachDir,s)>0) And Not(Pos('.BBF',s)>0) And Not(Pos('.BRF',s)>0)
					 Then Modem.OutLn ('Deleting -> '+ANSI.BRIGHT+s+ANSI.NORMAL);
				Erase(f);
			End;
		End;
	End; {If}
End; {P|Delete}


Procedure MakeDir (s : String);
Begin
	If Misc.ToHelp(s) Or (s='') Then Begin
		Help.On ('Make Directory');
		Exit;
	End;

	{$I-}
		MkDir (s);
	{$I+}

	If (IOResult<>0)Then Modem.OutLn ('Can''t create directory.')
			Else Modem.OutLn ('Creating directory '+ANSI.BRIGHT+s+ANSI.NORMAL);
End; {P|MD}


Procedure RemoveDir (s : String);
Var
	DirInfo : SearchRec;

Begin
	If Misc.ToHelp(s) Or (s='') Then Begin
		Help.On ('Remove Directory');
		Exit;
	End;

	If (s='*') Or (s='*.*') Or (s='.') Then Begin
		FindFirst ('*.*',DIRECTORY,DirInfo);
		If (DirInfo.Name='.') Or (DirInfo.Name='..') Then FindNext (DirInfo);
		If (DirInfo.Name='.') Or (DirInfo.Name='..') Then FindNext (DirInfo);
		While DosError=0 Do Begin
			If DirInfo.Attr=Directory Then Begin
			{$I-}
				RmDir (DirInfo.Name);
			{$I+}
				If IOResult<>0 Then Modem.OutLn	('Directory is not empty -> '+ANSI.BRIGHT+DirInfo.Name+ANSI.NORMAL)
					Else 	Modem.OutLn ('Removing directory -> '+ANSI.BRIGHT+DirInfo.Name+ANSI.NORMAL);
			End;
			FindNext (DirInfo);
		End;
	End Else Begin
		{$I-}
		RmDir (s);
		{$I+}
		If (IOResult<>0) Then Modem.OutLn ('Can''t remove directory. Bad name or directory not empty.')
			Else Modem.OutLn ('Removing directory -> '+ANSI.BRIGHT+s+ANSI.NORMAL);
	End;
End; {P|RD}

Procedure RenameFile (s : String);
Var F 			: File;
		Source,
		Target 	: String;
		Count 	: Byte;

Begin
	Count:=Pos (' ',s);
	If Not(Count>0) Or Misc.ToHelp(s) Then Begin
		Help.On ('Rename');
		Exit;
	End;

	Source:=Copy (s,1,Count-1);
	Target:=Copy (s,Count+1,Ord(s[0]));

	If Not(FileExists(Source)) Then Begin
		Modem.OutLn ('Source file '+ANSI.BRIGHT+Source+ANSI.NORMAL+' doesn''t exist.');
		Exit;
	End;

	If FileExists(Target) Then Begin
		Modem.OutLn ('Target file '+ANSI.BRIGHT+Target+ANSI.NORMAL+' already exist.');
		Exit;
	End;

	Assign (F,Source);
	Rename (F,Target);

	Modem.OutLn('Renaming '+ANSI.BRIGHT+Source+ANSI.NORMAL+' -> '+ANSI.BRIGHT+Target+ANSI.NORMAL);

End; {P|RenameFile}


Procedure StartLog;
Begin
	If Log And OpenLog Then Begin
		Modem.OutLn ('Log is already running.');
		Exit;
	End;

	Log:=TRUE;

	If Not(OpenLog) Then Begin
			Assign (FLog,LogFile);
			{$I-}
			Append (FLog);
			{$I+}
			IF IOResult<>0 Then Begin
				ReWrite (FLog);
				Modem.OutLn ('Creating new log: '+LogFile);
			End;
			OpenLog:=TRUE;
	End;
End;

Procedure CloseLog;
Begin
	If Not(Log) Then Begin
		Modem.OutLn ('Log isn''t turned On.');
		Exit;
	End;

	Log:=FALSE;
	If OpenLog Then Begin
			Close(FLog);
			OpenLog:=FALSE;
	End;
End;

Procedure MakeLog (s : String);
Begin
	If Misc.ToHelp(s) Then Help.On ('Log')
	Else If (s='ON') Or (s='1') Or (s='ENABLE') Then StartLog
	Else If (s='OFF') Or (s='0') Or (s='DISABLE') Then CloseLog
	Else If (s='NAME') Or (s='FILE') Then Modem.OutLn (LogFile)
	Else If (s='') Or (s='STATUS') 	Then
		Case Log Of
			TRUE : Modem.OutLn ('LOG is in process.');
			FALSE: Modem.OutLn ('LOG is turned off.');
		End

	Else if s<>''	Then Modem.OutLn ('Unknown option.');
End; {P|Log}

Procedure WriteAction2Log (s: String);
Begin
	If Not(Log) Then Exit; (* za svaki slucaj da ne okine *)
	If Not(OpenLog) Then StartLog;
	s:='['+Stat('DATE')+' '+Stat('TIME')+'] '+s;
	WriteLn (FLog,s);
End; {P|WriteAction2Log}


Procedure CD (Name : String);
Begin
	If Misc.ToHelp(Name) Then Help.On ('Change Directory')
	Else If (Pos(':',Name)>0) And (Right<SysOpRight) Then Modem.OutLn ('"'+Name+'" Don''t exist')
	Else If Name='' Then Modem.OutLn ('Missing name.')
	Else Begin
		{$I-}
		ChDir (Name);
		{$I+}
		If IOResult<>0 Then Modem.OutLn ('Directory '+Name+' does not exist.');
	End;
End; {P|ChangeDirectiory}


Procedure Tree (s: String);
Begin
	If Not(Red.CheckRed(s,'TREE.LOG')) Then Exit;
	If Misc.ToHelp(s) Then Help.On ('Tree')
	Else If (s='') Or Red.Redirect	Then BFiles.Show (TreeFile)
  Else If (s='/R') And (Right>=FileAdmRight) Then SysOp.Shell (GetEnv('SONIC_BBS')+'\BIN\C /L:'+TreeFile)
	Else If s<>'' Then Modem.OutLn ('Unknown option.');
	Red.HandleRedirect;
End; {P|Tree}


Procedure View (s: String);
Begin
	If Not(Red.CheckRed(s,'TYPE.LOG')) Then Exit;
	Red.HandleSign (s);

	If Misc.ToHelp(s) Then Help.On ('Type')
		Else If (Pos(':',s)>0) And (Right<SysOpRight) Then Modem.OutLn ('File name don''t exist.')
		Else If (Pos('*',s)>0) Or (Pos('?',s)>0) Then ShowFiles (s)
		Else If s<>'' Then BFiles.Show (s)
		Else If s='' 	Then Modem.OutLn ('Missing filename.');
	Red.HandleRedirect;
End; {P|View}


Procedure Helping (s: String);
Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Help');
		Exit;
	End;

	If Not(Red.CheckRed (s,'HELP.LOG')) Then Exit;
  If Right=SysOpRight Then BFiles.Show (SysOpHelpFile)
	Else If Right=FileAdmRight Then BFiles.Show (FileAdmHelpFile)
		Else BFiles.Show (NormalHelpFile);
	Red.HandleRedirect;
End; {P|Helping}


Procedure CopyFile (s: String);
Var
	SourceFile,
	TargetFile 	: File;
	Buffer 			: Array [1..1000] Of Byte;
	Count	 			: Integer;
	Cnt		 			: Byte;
	Source,
	Target			: String;
Begin
	Cnt:=Pos (' ',s);
	If Not(Cnt>0) Or Misc.ToHelp(s) Then Begin
		Help.On ('Copy');
		Exit;
	End;

	Source:=Copy (s,1,Cnt-1);
	Target:=Copy (s,Cnt+1,Ord(s[0]));

	{$I-}
	Assign (SourceFile,source);
	Reset (SourceFile,1);
	{$I+}
	If IOResult<>0 Then Begin
		Modem.OutLn ('Source file does not exist');
		Exit;
	End;


	If ((target[Ord(target[0])])='\') Then target:=target+source;

	Assign (TargetFile,target);
	ReWrite (TargetFile,1);

	BlockRead (SourceFile,Buffer,SizeOf(Buffer),Count);
	While Count>0 do begin
		BlockWrite (TargetFile,Buffer,Count);
		BlockRead  (SourceFile,Buffer,SizeOf(Buffer),Count);
	End;

	Close (SourceFile);
	Close (TargetFile);

	If Not(Pos(Pad.MailAttachDir,target)>0) Then
		Modem.OutLn (ANSI.BRIGHT+source+ANSI.NORMAL+' -> '+ANSI.BRIGHT+target+ANSI.NORMAL);
End;

Procedure Upload (fname: String); (* Download za korisnika *)
Begin
	If Misc.ToHelp(fname) Then Begin
		Help.On ('Download');
		Exit;
	End;
	If fname='' Then Begin
		Modem.OutLn ('Missing filename for downloading.');
		Exit;
	End;

	If Not(FileExists (fname)) Then Begin
		Modem.OutLn ('File '+fname+' does not exist.');
		Exit;
	End;

	Net.SetWhere ('Download');
	SysOp.Shell (GetEnv ('SONIC_BBS')+'\bin\zmodemu.bat '+fname);
	If DosError<>0 Then Modem.OutLn ('Error in File Transfer.');
	Net.SetWhere ('Sonic');
End;

Procedure Download (fname: String); (* Upload *)
Begin
	If Misc.ToHelp(fname) Then Begin
		Help.On ('Download');
		Exit;
	End;

	Net.SetWhere ('Upload');
	SysOp.Shell (GetEnv ('SONIC_BBS')+'\bin\zmodemd.bat');
	Net.SetWhere ('Sonic');
End;



End.
