{$O+,F+}

Unit	Config;

INTERFACE

Const
	CfgFile='BBS.CFG';

Var
	BBSName,
	ShortBaseFile,
	BigBaseFile,
	LogFile,
	WelcomeMessage,
	UploadDir,
	ZIPArchiver,
	ARJArchiver,
	LHAArchiver,
	ModemInitStr,
	ModemHangUp,
	TreeFile,
	ArcViewFile,
	MemFile,
	DescribeFile,
	MailBase,
	MailMessages,
	Editor,
	LocalEditFile,
	MailHelpFile,
	NormalHelpFile,
	FileAdmHelpFile,
	SysOpHelpFile,
	PadHelpFile,
	Logo,
	PadRootDir,
	MailAttachDir,
	AutoExecPath,
	AutoExecHelpFile,
	ResumeHelpFile,
	CommandsHelpFile,
	ResumeDir,
	BBSPath,
	DoorList,
	ZModemUl,
	ZModemDl,
	SessionsDir  	 : String;

	Log						 : Boolean;

	ComPort				 : Byte;
	ComPars				 : Byte;

	Guest					 : Integer;
	Normal				 : Integer;
	Benefit				 : Integer;
	FileAdm				 : Integer;
	SysOp					 : Integer;
	GuestTime      : Integer;
	NormalTime		 : Integer;
	BenefitTime		 : Integer;
	FileAdmTime		 : Integer;
	SysOpTime			 : Integer;


Procedure Make;


IMPLEMENTATION

Uses
	DOS;

Function Upper (s : String) : String;
var
	i : Integer;
	d : Byte;
Begin
	d:=Ord(s[0]);
	For i:= 1 To d Do
		s[i]:=UpCase(s[i]);
	Upper:=s;
End; {F||Upper : String}

Procedure Parser (s : String);
Var
	i 					: Integer;
	Len,b				: Byte;
	Left,Right	: String;
Begin
	Len		:= Length (s);
	If Pos (';',s)=1 Then Exit; (* Provjerava za komentare *)
	If Len<2 Then Exit;					(* Provjerava za praznu liniju *)
	b			:= Pos ('=',s);
	Left	:= Copy (s,1,b-1);
	Right	:= Copy (s,b+1,Len);
	Left  := Upper (Left);
	If Left='BBSNAME' 						Then BBSName:=Right
	Else If Left='SHORTBASEFILE'  Then ShortBaseFile:=Right
	Else If Left='BIGBASEFILE'    Then BigBaseFile:=Right
	Else If	Left='LOG'            Then
		If (Upper(Right)='YES') Or (Upper(Right)='TRUE')
			Then Log:=TRUE
			Else Log:=FALSE
	Else If Left='LOGFILE'        Then LogFile:=Right
	Else If Left='WELCOMEMESSAGE' Then WelcomeMessage:=Right
	Else If Left='UPLOADDIR'      Then UpLoadDir:=Right
	Else If Left='ZIPARCHIVER'    Then ZIPArchiver:=Right
	Else If Left='ARJARCHIVER'    Then ARJArchiver:=Right
	Else If Left='LHAARCHIVER'		Then LHAArchiver:=Right
	Else If Left='GUEST'					Then Val (Right,Guest       ,i)
	Else If Left='NORMAL'         Then Val (Right,Normal      ,i)
	Else If Left='BENEFIT'        Then Val (Right,Benefit     ,i)
	Else If Left='FILEADM'        Then Val (Right,FileAdm     ,i)
	Else If Left='SYSOP'          Then Val (Right,SysOp       ,i)
	Else If Left='GUESTTIME'			Then Val (Right,GuestTime   ,i)
	Else If Left='NORMALTIME'			Then Val (Right,NormalTime  ,i)
	Else If Left='BENEFITTIME'		Then Val (Right,BenefitTime ,i)
	Else If Left='FILEADMTIME'    Then Val (Right,FileAdmTime ,i)
	Else If Left='SYSOPTIME'			Then Val (Right,SysOpTime   ,i)
	Else If Left='MODEMINITSTR'   Then ModemInitStr:=Right
	Else If Left='MODEMHANGUP'		Then ModemHangUp:=Right
	Else If Left='TREEFILE'				Then TreeFile:=Right
	Else If Left='ARCVIEWFILE'    Then ArcViewFile:=Right
	Else If Left='MEMFILE'				Then MemFile:=Right
	Else If Left='COMPORT'				Then Val (Right,ComPort, i)
	Else If Left='COMPARS'				Then Val (Right,ComPars, i)
	Else If Left='DESCRIBEFILE'		Then DescribeFile:=Right
	Else If Left='MAILBASE'				Then MailBase:=Right
	Else If Left='MAILMESSAGES'   Then MailMessages:=Right
	Else If Left='EDITOR'					Then Editor:=Right
	Else If Left='LOCALEDITFILE'	Then LocalEditFile:=Right
	Else If Left='MAILHELPFILE'   Then MailHelpFile:=Right
	Else If Left='NORMALHELPFILE' Then NormalHelpFile:=Right
	Else If Left='FILEADMHELPFILE'Then FileAdmHelpFile:=Right
	Else If Left='SYSOPHELPFILE'  Then SysOpHelpFile:=Right
	Else If Left='PADHELPFILE'		Then PadHelpFile:=Right
	Else If Left='LOGO'						Then Logo:=Right
	Else If Left='PADROOTDIR'			Then PadRootDir:=Right
	Else If Left='MAILATTACHDIR'	Then MailAttachDir:=Right
	Else If Left='AUTOEXECDIR'    Then AutoExecPath:=Right
	Else If Left='AUTOEXECHELPFILE'	Then AutoExecHelpFile:=Right
	Else If Left='RESUMEHELPFILE'   Then ResumeHelpFile:=Right
	Else If Left='COMMANDSHELPFILE' Then CommandsHelpFile:=Right
	Else If Left='RESUMEDIR'        Then ResumeDir:=Right
	Else If Left='BBSPATH'          Then BBSPath:=Right
	Else If Left='DOORLIST'					Then DoorList:=Right
	Else If Left='ZMODEM-UPLOAD' 		Then ZModemUl:=Right
	Else If Left='ZMODEM-DOWNLOAD'	Then ZModemDl:=Right
	Else WriteLn ('What a hell is ',Left,' mothere ti.');
End; {P|Parser}

Procedure Make;
Var
	s : String;
	F : TEXT;
Begin
	Assign (F,GetEnv('SONIC_BBS')+'\'+CfgFile); (* CFG file ide uvijek u isti dir *)
	{$I-}
	Reset (F);
	{$I+}
	If IOResult<>0 Then Begin
		WriteLn ('BBS.CFG don''t exist');
		Exit;
	End;
	While Not(EOF(F)) Do Begin
		ReadLn (F,s);
		Parser (s);
	End;
	Close (F);
End; {P|OpenCfg}

End.

==========================================================================
Configuration Unit for BBS, 2 feb '93:
--------------------------------------------------------------------------
	add on  9 feb '93.
		- treefile (for tree cmd)
		- arcviewfile (for av or archive view cmd)
		- helpfile (for help command)
		- memfile (for mem command)
	add on 10 feb '93.
		- comport	(for modem unit)
		- compars (for modem unit)
	add on 11 feb '93.
		- describefile (for dir command, description of file)
	add on 14 feb '93.
		- mailbase (for mail command) (base for mail)
		- mailmessages (for mail command) (where are stored mails)
	add on 17 feb '93.
		- editor (for working in local, loads external editor)
		- localeditfile (name of local working file used by extarnal editor)
	add on 21 feb '93.
		- mailhelpfile (help file for mail command prompt)
	del on 23 feb '93.
		- helpfile (for help command)
	add on 23 feb '93.
		- normalhelpfile (help file for normal user)
		- fileadmhelpfile (help file for fileadm user)
		- sysophelpfile (help file for sysop)
	chg on  3 apr '93.
		- you must implicit take init, not just including config
	add on  7 apr '93.
		- padhelpfile (help for pad system)
	add on  8 apr '93.
		- logo (where is stored welcome file ex. logo.bbs)
	add on 10 apr '93.
		- padrootdir (where is placed root of users pads)
	add on 12 apr '93.
		- lhaarchiver (for archiver, non-pc)
	add on 19 apr '93.
		- mailattachdir (where are placed attached files for mail)
	add on 27 apr '93.
		- autoexecpath  (where are placed autoexecs for users)
		- autoexechelpfile (file for help or ? in autoexec mode)
	add on  2 may '93.
		- commandshelpfile (where are descriptions of commands (help) )
	add on 12 may '93.
		- resumehelpfile (where are placed help for users)
		- resumedir (where are placed all resumes of users)
	add on 20 may '93.
		- bbspath (where is executable bbs files eg. c:\bbs)
		- doorlist (flie where is placed list of doors)
--------------------------------------------------------------------------
