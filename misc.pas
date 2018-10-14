{$O+,F+}

Unit	Misc;

INTERFACE

Const
	Enter		=	#13#10;
	Right		: Byte    = 1;
	Quit  	: Boolean = FALSE;
	Local 	: Boolean = FALSE;
	TimeOut	:	Boolean = FALSE;
	Ring		: Boolean = FALSE;
	MesgOff : Boolean = FALSE;
	Parsing : Boolean = FALSE;

	ToDecrement	=	1;
	ToIncrement	=	2;

Var
	StopMinut 	 : Word;

	ToCommandMode,
	Uzvicnik,
	MailPrompt,
	PadPrompt,
	AutoExecPrompt,	 
	ResumePrompt,
	DoorPrompt,
	ChatPrompt		: Boolean;

	Command,
	OriginalCommand,
	Username,
	Password 			: String;

	Function ToHelp 		(s: String)				: Boolean;
	Function Execute 		(CmdLine: String)	: Boolean;
	Function Upper 			(s : String) 			: String;
	Function Lower 			(s : String)			:	String;
	Function MakeBlanks (what : String) 	: String; (* 15 znakova *)
	Function Stat 			(c : String) 			: String;

	Procedure Dir 							(Filter,Options : String);
	Procedure Init;
	Procedure LogOut						(s : String; stay: Boolean);
	Procedure Prompt;
	Procedure CLS 							(s : String);
	Procedure LogIn;
	Procedure UserStat 					(s,options : String);
	Procedure Finger 						(s: String);
	Procedure TimeHandling 			(mode: Byte; Min: Integer);
	Procedure ReLog 						(s: String);
	Procedure SetMailMode 			(ToWhat : Boolean);
	Procedure CommandModeParser (s,rest,options:String);
	Procedure Parser 						(s : String);
	Procedure Redirect;
	Procedure StartSession;
	Procedure TakeCommands;

IMPLEMENTATION

Uses
	ANSI,
	AutoExec,
	BBegin,
	BBSBase,
	BFiles,
	BigBase,
	BTimer,
	Config,
	CRT,
	DOS,
	Door,
	Help,
	Mail,
	Modem,
	Net,
	Pad,
	Red,
	Resume,
	SysOp;

Const
	Path	:	String 	= '';

Var
	Logo,
	NormCaps  : String;


(*---------------------------------------------------------------*)
Procedure Init;
Begin
	Config.Make;
	BBSBase.Base					  :=	Config.ShortBaseFile;
	BigBase.BigBaseFile		  :=	Config.BigBaseFile;
	Misc.Logo						  	:=  Config.Logo;
	SysOp.MemFile				  	:=	Config.MemFile;
	Modem.Local					  	:=  Local;
	Mail.MailBase					  :=  Config.MailBase;
	Mail.MailMessages 	    :=  Config.MailMessages;
	Mail.Editor						  :=  Config.Editor;
	Mail.LocalEditFile	    :=  Config.LocalEditFile;
	Pad.PadRootDir			  	:=  Config.PadRootDir;
	Pad.MailAttachDir   	  :=  Config.MailAttachDir;
	BFiles.ArcViewFile		  :=	Config.ArcViewFile;
	BFiles.DescribeFile	  	:=	Config.DescribeFile;
	BFiles.LogFile				  :=	Config.LogFile;
	BFiles.Log						  :=	Config.Log;
	BFiles.SysOpRight     	:=  Config.SysOp;
	BFiles.FileAdmRight   	:=  Config.FileAdm;
	BFiles.TreeFile					:=	Config.TreeFile;
	BFiles.NormalHelpFile 	:=  Config.NormalHelpFile;
	BFiles.FileAdmHelpFile	:=  Config.FileAdmHelpFile;
	BFiles.SysOpHelpFile  	:=  Config.SysOpHelpFile;
	BFiles.MailHelpFile			:=  Config.MailHelpFile;
	BFiles.PadHelpFile			:=	Config.PadHelpFile;
	BFiles.AutoExecHelpFile	:=  Config.AutoExecHelpFile;
	BFiles.ResumeHelpFile   :=  Config.ResumeHelpFile;
	BFiles.DoorList					:=  Config.DoorList;
	AutoExec.AutoExecPath 	:= 	Config.AutoExecPath;
	Help.HelpFile						:=  Config.CommandsHelpFile;
	Resume.ResumeDir				:=  Config.ResumeDir;
	Door.BBSPath						:=  Config.BBSPath;
End; {P|Init}


(*------------------------------------------------------------------*)
Procedure Dir (Filter,Options : String);
Var
	DirInfo	: SearchRec;
	Duzina,
	Count		: Byte;
	s,
	line,
	FileName: String;
	F				: Text;
	Descript: Boolean;

Begin
	If Not(Red.CheckRed (Filter+Options,'DIR.LOG')) Then Exit;
	Red.HandleSign (Filter);

	If Misc.ToHelp(s) Then Help.On ('Dir')
	Else If (Filter='PAD:') Then PadModeParser ('DIR','*.*','')
	Else If (Pos(':',Filter)>0) And Not(Right=Config.SysOp) Then Begin
		Modem.OutLn ('Directory does not exist.');
		Red.HandleRedirect;
		Exit;
	End
	Else Begin
		If (Filter='..') Then Filter:='..\*.*';
		If (Filter='') Or (Filter='.') Or (Pos('>',Filter)>0) Then Filter:='*.*';
		If Pos('\',Filter)=(Ord(Filter[0])) Then Filter:=Filter+'*.*';

		FindFirst(Filter, Directory, DirInfo);
		{$I-}
		Assign (F,DescribeFile);
		Reset (F);
		{$I+}
		Descript:=TRUE;
		If IOResult<>0 Then Descript:=FALSE;
		Count:=1;

		While DosError = 0 do	Begin
			Duzina:=Ord(DirInfo.Name[0]);

			If Not((DirInfo.Name='.') Or (DirInfo.Name='..')) Then
				If DirInfo.Attr=Directory Then Begin

					Modem.Out (ANSI.BLUE);
					Modem.Out (Upper(DirInfo.Name)+'/');

					s:='';
					INC (Count);
					If (Count=Width) And Not(Red.Redirect) Then Begin
						If Not(Modem.Rest('Continue')) Then Exit;
						Count:=1;
					End;

					If Descript Then Begin
						{$I-}
						Reset(F);
						{$I+}
						If IOResult=0 Then
							While Not Eof(F) do begin
								ReadLn (F,Line);
								If Pos (Lower(DirInfo.Name),Line)=1 Then
								s:=Copy (Line,Ord(DirInfo.Name[0])+1,Ord(Line[0]));
							End; {While}
						End; {If}
						Modem.OutLn (s);
					End; {If}
			FindNext (DirInfo);
		End; {While}
		If Descript Then Close (F);

		FindFirst(Filter, Archive, DirInfo);
		{$I-}
		Assign (F,DescribeFile);
		Reset (F);
		{$I+}
		If IOResult<>0 Then Descript:=FALSE;

		While DosError = 0 do
		Begin
			Duzina:=Ord(DirInfo.Name[0]);
			If (DirInfo.Attr=Archive) Then Begin

				FileName:=Lower(DirInfo.Name);
				Modem.Out (ANSI.GREEN);
	
				Modem.Out (Misc.MakeBlanks(Lower(FileName)));

				Str (DirInfo.Size:7,s);
				Modem.Out (s);

				s:='';
				INC(Count);
				If(Count=Width) And Not(Red.Redirect) Then Begin
						If Not(Modem.Rest ('Continue')) Then Exit;
						Count:=1;
				End;

				If Descript Then Begin
					{$I-}
					Reset (F);
					{$I+}

					If IOResult=0 Then
						While Not Eof(F) do begin
							ReadLn (F,Line);
							If Pos (FileName,Line)=1 Then
								s:=Copy (Line,Ord(FileName[0])+1,Ord(Line[0]));
						End;
				End;

				Modem.OutLn (s);
			End;
			FindNext (DirInfo);
		End;
		If Descript Then Close (F);
	End;
	Red.HandleRedirect;
End; {P|Dir}

Function ToHelp (s: String): Boolean;
Begin
	ToHelp:=(Pos('/?',s)>0) Or (Pos('/H',s)>0) Or (Pos('/HELP',s)>0);
End; (* Provjerava dali sadrzi switch za Help *)

Function Execute (CmdLine: String): Boolean;
Begin
	SwapVectors;
	Exec (GetEnv('COMSPEC'), CmdLine);
	SwapVectors;
	If DosError<>0	Then Execute:=False
									Else Execute:=True;
End; (* Izvrsava DOS komandu ili neki file *)


Procedure LogOut (s : String; stay: Boolean);
Var
	OnLineStr,
	RestStr : String;

Begin
	If ToHelp(s) Then Begin
		Help.On ('Logout');
		Exit;
	End;

	If Not(Modem.Rest ('Logout')) Then Exit;

	Net.SetWhere ('Logging out');
	Modem.Out (#10#13#13);

	BFiles.WriteAction2Log ('Logout: '+Username+#13#10);

	Pad.Stop;

	BigBase.DecrementDayTime;
	BigBase.IncrementOnLineTime;

	Str (BTimer.OnLine,OnLineStr);
	Str (RestMinutes-BTimer.OnLine,RestStr);

	Modem.OutLn ('Today is '+Stat ('DATE')+' '+Stat ('TIME'));
	Modem.OutLn ('Total time spent '+ANSI.BRIGHT+OnLineStr+ANSI.NORMAL+', remaining time for today '+
								+ANSI.BRIGHT+RestStr+ANSI.NORMAL+'.'+Enter);
	Modem.OutLn ('Goodbye '+ANSI.BRIGHT+MISC.UserName+ANSI.NORMAL+', see you soon.'+Enter);

	If Not(Stay) Then Quit:=TRUE;
End; (* Izlazak sa sistema *)


Function Lower (s: String) : String;
Var	len,count : Byte;
Begin
	len:=Ord(s[0]);
	For	count:=1 to len do
		If s[count] In ['A'..'Z'] Then s[count]:=Chr(Ord(s[count])+32);
	Lower:=s;
End; (* "Spusta" sva slova u stringu *)

Function Upper (s : String) : String;
Var
	i : Integer;
	d : Byte;
Begin
	d:=Ord(s[0]);
	For i:= 1 To d Do
		s[i]:=UpCase(s[i]);
	Upper:=s;
End; (* "Dize" sva slova u stringu *)

Procedure AllPromptFalse;
Begin
	MailPrompt		:= FALSE;
	PadPrompt			:= FALSE;
	AutoExecPrompt:= FALSE;
	ResumePrompt  := FALSE;
	DoorPrompt    := FALSE;
	ChatPrompt		:= FALSE;
End; (* Sve promptove postavlja na false *)

Procedure Prompt;
Var
	CurrentDir : String;
Begin
	If MailPrompt 					Then Modem.Out (ANSI.BRIGHT+'Mail'    +ANSI.NORMAL+' ¯ ')
	Else If PadPrompt 			Then Modem.Out (ANSI.BRIGHT+'Home'    +ANSI.NORMAL+' ¯ ')
	Else If AutoExecPrompt 	Then Modem.Out (ANSI.BRIGHT+'AutoExec'+ANSI.NORMAL+' ¯ ')
	Else If ResumePrompt		Then Modem.Out (ANSI.BRIGHT+'Resume'  +ANSI.NORMAL+' ¯ ')
	Else If DoorPrompt      Then Modem.Out (ANSI.BRIGHT+'Door'    +ANSI.NORMAL+' ¯ ')
	Else If ChatPrompt			Then Modem.Out ('¯ ')
	Else Begin
			GetDir (0,CurrentDir);
			Modem.Out (ANSI.BRIGHT+Lower(CurrentDir)+ANSI.NORMAL+' ¯ ');
			Path:=CurrentDir;
			AllPromptFalse;
		End;
	TimeOut:=BTimer.IsTimeOut;
End; (* Ispis prompta *)


Function Stat (c : String) : String;
Const
	days : Array [0..6] Of String[9] = ('Sunday',
																			'Monday',
																			'Tuesday',
																			'Wednesday',
																			'Thursday',
																			'Friday',
																			'Saturday');
Var
	h, m, s, hund,
	y, mm, d, dow : Word;
	dan,
	mesec,
	godina : String;

	Function LeadingZero(w : Word) : String;
	Var s: String;
	Begin
		Str(w:0,s);
		If Ord(s[0])=1 Then s:='0'+s;
		LeadingZero := s;
	End;

Begin
	If ToHelp(c) Then Begin
		Help.On ('Show');
		Stat:='';
	End
	Else If (c='DA') Or (c='DATE') Then Begin
		GetDate(y,mm,d,dow);

		Str(mm:0,mesec);
		Str(d:0,dan);
		Str(y:0,godina);

		If BFiles.LOG Then Stat:=mesec+'-'+dan+'-'+godina
									Else Stat:=days[dow]+' '+mesec+'-'+dan+'-'+godina;
	End
	Else If (c='TI') Or (c='TIME') Then Begin
		GetTime(h,m,s,hund);
		Stat:=LeadingZero(h)+':'+LeadingZero(m)+':'+LeadingZero(s);
	End
	Else If (c='') Then Begin
		Modem.OutLn ('Today is '+Stat('DA')+', '+Stat('TI'));
		Modem.OutLn ('');

		Str(BTimer.OnLine:3,Dan);
		Str((RestMinutes-BTimer.OnLine):3,Mesec);

		Modem.OutLn ('This connection time - '+Dan+' Minute(s)');
		Modem.Out   ('Rest  On-Line   time - '+ANSI.BRIGHT+Mesec+ANSI.NORMAL+' Minute(s)');

		Stat:='';
	End Else Begin
		Modem.OutLn ('Illegal option.');
		Stat:='';
	End;
End; (* Datum, vrijeme, jos koliko je ostalo do kraja, dosad *)


Function MakeBlanks (what : String) : String;
Var i,Len : byte;
Begin
	Len:=Ord(what[0]);
	If Len<15 then
		For	i:=Len to 14 do
			what:=what+' ';
	MakeBlanks:=What;
End; (* Dopunjuje string koji je kraci od 15 znakova na 15 znakova *)


Procedure CLS (s : String);
Begin
	If ToHelp(s) Then Help.On ('Cls')
		Else Modem.OutLn (ANSI.CLS)
End; (* Brise ekran *)


Procedure UserStat (s,options : String);
Begin
	If ToHelp(s) Then Help.On ('Stat')
		Else If (s='')	Then BigBase.ShowUserStat (Username,options)
		Else If (s<>'') And (Right=Config.SysOp) Then BigBase.ShowUserStat (s,options);
End; (* Stat naredba, najrazlicitiji podaci *)


Procedure Finger (s: String);
Begin
	If ToHelp(s) Then Help.On ('Finger')
		Else BBSBase.ShowDatas (TRUE,s);
End; (* Finger naredba, pregled korisnika na sistemu *)


Procedure Echo (s: String);
Begin
	If ToHelp(s) Then Help.On ('Echo')
	 Else Modem.OutLn (OriginalCommand);
End; (* Echo naredba *)


Procedure Pause (s: String);
Begin
	If ToHelp(s) Then Help.On ('Pause')
		Else Begin
			Modem.OutLn (OriginalCommand);
			Modem.TakeCommand(Not(Misc.MesgOff));
		End;
End;


Procedure TimeHandling (mode: Byte; Min: Integer);
Var sMin : String[3];
Begin
	Case mode of
		ToDecrement : Begin
										BTimer.TakeTime (Min);
										Dec (RestMinutes,Min);
									End;
		ToIncrement : Begin
										BTimer.GiveTime (Min);
										Inc (RestMinutes,Min);
									End;
	End;
	Str (RestMinutes,sMin);
	Modem.Out (Enter+'Rest On-Line time '++ANSI.BRIGHT+sMin+ANSI.NORMAL+' minutes.');
End; (* ALT +/- povecavanje/smanjenje vremena korisnika *)


Procedure LogIn;
Var
		attemp 	 : Byte;
		temp,
		password : String;
		Ok,
		Guest,
		New			 : Boolean;
Begin
	AllPromptFalse;
	ToCommandMode	:= FALSE;
	Uzvicnik			:= FALSE;
	New						:= FALSE;
	Guest					:= FALSE;


	If Not(Local) Then BFiles.WriteAction2Log ('RING recived');
	If Local 			Then BFiles.WriteAction2Log ('LOCAL session');

	BFiles.Show (Logo);

	attemp:=1;
	BBSBase.Open_Dbf;
	Repeat
		Modem.Out ('Username: ');
		Username:=Modem.TakeCommand(FALSE);
		Username:=Lower(UserName);
		Modem.OutLn ('');

		If (Upper(Username)='GUEST')  Then Begin
			Ok:=TRUE;
			Guest:=TRUE;
			BBSBase.Close_Dbf;
		End
		Else If (Upper(Username)='NEW')  Then Begin
			Ok:=TRUE;
			New:=TRUE;
			BBSBase.Close_Dbf;
		End Else Ok:=BBSBase.IsUser(Username);

		If Not(Ok) Then Begin
			INC (attemp);
			If attemp=100 Then Begin
				Modem.OutLn ('Access Denied.');
				BBSBase.Close_Dbf;
				(*
					Ubaciti da se vrati na cekanje veze
				*)
				Halt;
			End Else Modem.OutLn ('Username do not exist. Type GUEST for first login.'+Enter);
		End;
	Until Ok;

	If BFiles.Log Then BFiles.WriteAction2Log ('Username: '+Username);
	attemp:=1;
	BigBase.Username:=Username;

	Repeat
		Modem.Out ('Password: ');
		Modem.Hide:=TRUE;
		Password:=TakeCommand(FALSE);
		Modem.Hide:=FALSE;
		Modem.OutLn ('');

		If Guest Or New Then Ok:=True
										Else	Ok:=BBSBase.IsPassword (username,password);

		If Not(Ok) Then Begin
			INC (attemp);
			If attemp=100 Then Begin
				Modem.OutLn ('Access Denied.');
				BBSBase.Close_Dbf;
				Halt (0);
			End Else Begin
				BBSBase.Close_Dbf;
				BigBase.Open_Dbf;
				If BFiles.Log Then BFiles.WriteAction2Log ('BAD Password Attempt -> '+password);
				If Not(BigBase.BIsUser) Then BigBase.MakeUser;
				BigBase.IncrementField ('BADPASS');
				BigBase.Close_Dbf;
				BBSBase.Open_Dbf;
				Modem.OutLn ('Password is not correct.'+Enter);
			End;
		End;
	Until Ok;

	If Guest Then Begin
		UserRight:=Config.Guest;
		Misc.Right:=UserRight;

		Pad.Dont:=TRUE;

		BTimer.UserRight:=UserRight;
		BTimer.DefineTime;

		AutoExec.UserName:='guest';
		AutoExec.Start (0,Running,'');

		Exit;
	End;

	If New Then Begin
		AutoExec.UserName:='new';
		AutoExec.Start (0,Running,'');
		SysOp.NewUser ('',TRUE);
		Misc.Quit:=TRUE;
		Exit;
	End;

	Misc.Right:=BBSBase.UserRight;
	BigBase.Right:=BBSBase.UserRight;

	BBSBase.Close_Dbf;
	BigBase.Open_Dbf;

	Modem.OutLn ('');
	If Not(BigBase.BIsUser) Then BigBase.MakeUser;

	BigBase.ShowLastDateAndTime;
	BigBase.IncrementField ('CONNECT');
	BigBase.SetLastDateAndTime;
	BigBase.SetArchiver;

	BigBase.Close_Dbf;
	BBSBase.Open_Dbf;

	Pad.Dont:=FALSE;
	Pad.UserName:=UserName;
	Pad.DefineUserDir;
	
	Misc.UserName:=Username;
	Misc.Right:=BBSBase.UserRight;

	BTimer.UserRight:=BBSBase.UserRight;
	BTimer.DefineTime;

	BBSBase.Close_Dbf;

	Mail.Username:=Username;

	If (Mail.FindMail) And (Mail.NumberOfMails>0) Then Begin
		Str (Mail.NumberOfMails,temp);
		Modem.OutLn (Enter+#7+'You have '+ANSI.BRIGHT+temp+' new'+ANSI.NORMAL+' Mail(s).');
	End;

	Net.Register (Username);

	Pad.Start;

	If Config.Log Then BFiles.CloseLog;

	Net.SetWhere ('Running Autoexec');

	AutoExec.UserName:=Username;
	If Not(Username='anubis') Then AutoExec.Start (1,Running,'');     (* TOALL.BBF *)
	AutoExec.Start (0,Running,'');     (* User BBF  *)
	If Config.Log Then BFiles.StartLog;

	Net.SetWhere ('Sonic');

	Resume.UserName:=Resume.DefineUserFile(Username);
End; (* Login procedura *)


Procedure ReLog (s : String);
Var
	OnLineStr,
	RestStr : String;

Begin
	If ToHelp(s) Or (s<>'') Then Begin
		Help.On ('Relog');
		Exit;
	End;

	Net.SignOff;
	LogOut ('',TRUE);
	LogIn;
End; (* Ponovni Login bez iskljucivanja veze *)

procedure Reboot (s: String);
Var
	Warm:	Boolean;
begin
	If s='COLD' Then Warm:=FALSE
		Else If s='WARM' Then  Warm:=TRUE
		Else Begin
			Help.On ('Reboot');
			Exit;
	End;

  { Warm = true triggers warm boot with no memory test }
  if Warm then
    MemW[$0040:$0072] := $1234
  else
  { Warm = false triggers cold boot with full memory test }
    MemW[$0040:$0072] := 0;

  inline($EA/$00/$00/$FF/$FF);  { JMP FFFF:0 }
end;

Procedure Display (s: String);
Begin
	If (s='MAIL') Or (s='MAILBASE') Then Mail.DisplayMailBase
		Else If (s='BBS') Or (s='BBSBASE') Then BBSBase.DisplayBBSBase
		Else If (s='BIG') Or (s='BIGBASE') Then BigBase.DisplayBigBase
		Else Help.On ('DISPLAY');
End;

Procedure SetMode (var mode:boolean);
Begin
	AllPromptFalse;
	mode:=TRUE;
	If MailPrompt Then Net.SetWhere ('Mail')
	Else If PadPrompt 			Then Net.SetWhere ('Home')
	Else If AutoExecPrompt 	Then Net.SetWhere ('AutoExec')
	Else If ResumePrompt		Then Net.SetWhere ('Resume')
	Else If DoorPrompt      Then Net.SetWhere ('Door')
	Else If ChatPrompt			Then Net.SetWhere ('Chat')
	Else Net.SetWhere ('Sonic');
End; (* Brise sve ostale modove i postavlja trazeni mod prompta *)

Procedure Chatuj;
Begin
	Net.SetWhere ('Chat');
	SetMode (ChatPrompt);
	Net.SetChat (TRUE);
	Modem.OutLn ('[Entering the chat]');
End;


Procedure SetMailMode (ToWhat : Boolean);
Begin
	MailPrompt:=ToWhat;
	Misc.MailPrompt:=ToWhat;
End; {SetMailMode}


Procedure CommandModeParser (s,rest,options: String);
Var
	duz: Byte;

Begin
	duz:=Ord(s[0]);
	If (s[duz]='\') Then Begin  (* imedir\ tretira kao cd imedir *)
		s[0]:=Chr(duz-1);
		BFiles.CD (s);
		Exit;
	End;

	If (s='CD')	 Then	BFiles.CD  (rest)
	else If (s='TYPE') Or
					(s='TY')   Or
					(s='CAT')  Then BFiles.View 		(rest+options)

	else if (s='CD..') Or
					(s='..') 	 Then BFiles.CD 			('..')
	else if (s='CD\')  Or
					(s='\')  	 Or
					(s='/') 	 Then BFiles.CD 			('\')

	else If (s='TREE') Then BFiles.Tree 		(rest)
	else If (s='VIEW') Or (s='VI')	 Then BFiles.AV 		 (rest+options)
	else If (s='?') 	 Or (s='HELP') Then BFiles.Helping (rest)

	else If (s='DO') Or
					(s='DL') Or
					(s='DOWNLOAD') Then BFiles.Upload (rest)
	else If (s='UL') Or
					(s='UP') Or
					(s='UPLOAD') Then BFiles.Download (rest)

	else If (s='DIR') Or
					(s='DI')  Or
					(s='LS')  Then Dir (rest,options)

	else If (s='CLS')												Then Misc.CLS			(rest)
	else If (s='ECHO')											Then Misc.Echo    (rest+' '+options)
	else If (s='FINGER') Or (s='FIN') 			Then Misc.Finger  (rest)
	else if (s='PAUSE')											Then Misc.Pause   (rest)
	else If (s='STAT')											Then Misc.UserStat(rest,options)
	else If (s='LO') Or
					(s='LOGOUT') Or
					(s='BYE') Or
					(s='QUIT')	Then Misc.LogOut 	(rest,FALSE)
	else If (s='SET')												Then BigBase.SetCmd  (rest)
	else If (s='SHOW') Or (s='SH') 					Then Modem.OutLn 	(Misc.Stat (rest))
	else If (s='TIME') Or (s='TI')          Then Modem.OutLn  (Misc.Stat ('TIME'))
	else If (s='DATE') Or (s='DA')          Then Modem.OutLn  (Misc.Stat ('DATE'))
	else If (s='REM')	 Or (s='REMARK')			Then Exit
	else If (s='VER') 											Then Help.On ('Sonic version')
	else If (s='PAR')  Or (s='PARSE')       Then Pad.Parse (rest,options)
	else If (s='WHO')  											Then Net.Who (Rest)
	else If (s='SEND') Or (s='WRITE') Or (s='SE') Or (s='PAGE') Then Net.SendTo (rest,options)
	else If (s='MESG') 											Then Net.Mesg (Rest)
	else If (s='CHAT')											Then Chatuj

	else If (s='PAD')	Or (s='HOME') Or (s='HO') Or (s='~') Then Begin (* PAD rezim *)
		If (Rest='') 	Then SetMode(PadPrompt);
		If (Rest<>'') Then Pad.PadModeParser (Rest,Options,'');
	end

	else if (s='MAIL') Or (s='MA') Then Begin  (* MAIL rezim *)
		If (Rest='') 	Then SetMode (MailPrompt);
		If (Rest<>'') Then Mail.MailModeParser (Rest,Options,'');
	end

	else if (s='AUTOEXEC') Or (s='AUTO') Then Begin (* Autoexec *)
		If (Rest='') 	Then SetMode (AutoExecPrompt);
		If (Rest<>'') Then AutoExec.AutoExecModeParser (Rest,Options,'');
	end

	else if (s='RESUME') Or (s='RES') Then Begin (* Resume mode *)
		If (Rest='') Then SetMode (ResumePrompt);
		If (Rest<>'') Then Resume.Parser (Rest,Options,'');
	end

	else if (s='DOOR') Then Begin (* Door mode *)
		If (Rest='') Then SetMode (DoorPrompt);
		If (Rest<>'') Then Door.DoorModeParser (Rest,Options,'');
	end

	else If (Not(UserRight<Config.FileAdm) And (s='LOG'))  	Then BFiles.MakeLog    (rest)
	else if (Not(UserRight<Config.FileAdm) And (s='MD'))    Then BFiles.MakeDir	   (rest)
	else if (Not(UserRight<Config.FileAdm) And (s='RD'))    Then BFiles.RemoveDir	 (rest)
	else if (Not(UserRight<Config.FileAdm) And (s='COPY'))  Then BFiles.CopyFile	 (rest+' '+options)
	else If (Not(UserRight<Config.FileAdm)) And ((s='DELETE')   Or (s='DEL'))  Then BFiles.DeleteFile (rest)
	else if (Not(UserRight<Config.FileAdm)) And ((s='RENAME')   Or (s='REN'))  Then BFiles.RenameFile (rest+' '+options)
	else if (Not(UserRight<Config.FileAdm)) And ((s='DESCRIBE') Or (s='DESC')) Then BFiles.Describe   (rest)

	else If (Not(UserRight<Config.SysOp) And (s='MEM'))		Then SysOp.DOS_Memory (rest)
	else If (Not(UserRight<Config.SysOp) And (s='OS'))	 	Then SysOp.Shell (rest)
	else If (Not(UserRight<Config.SysOp) And (s='NEW'))		Then SysOp.NewUser (rest,FALSE)
	else If (Not(UserRight<Config.SysOp) And (s='RELOG'))	Then Relog ('')
	else If (Not(UserRight<Config.SysOp) And (s='KILL'))	Then SysOp.KillUser (rest)
	else If (Not(UserRight<Config.SysOp) And (s='ALL'))		Then SysOp.All (rest)
	else If (Not(UserRight<Config.SysOp) And (s='RECONFIG'))Then Init
	else If (Not(UserRight<Config.SysOp) And (s='MAKE') And (rest='MAIL'))     Then Mail.MakeNewMail
	else If (Not(UserRight<Config.SysOp) And (s='MAKE') And (rest='BIGBASE')) Then BigBase.Create_New_Base
	else If (Not(UserRight<Config.SysOp) And (s='MAKE') And (rest='BBSBASE')) Then BBSBase.NewBase
	else If (Not(UserRight<Config.SysOp) And (s='MAKE') And (rest='10'))      Then Make10Mails  (options)
	else If (Not(UserRight<Config.SysOp) And (s='DISPLAY')) Then Display (Rest)
	else If (Not(UserRight<Config.SysOp) And (s='REBOOT')) Then Misc.Reboot (rest)
	else If (Not(UserRight<Config.SysOp) And (s='EDITUSER')) Then BBSBase.EditUser (rest)

	else If s<>'' Then Modem.OutLn ('Unknown command "'+s+'", type ? for Help.');
End; (* Parser za komande (glavni) *)


Function CommandMode : Boolean;
Var Temp1,
		Temp2 : Boolean;
Begin
	Temp1:=Not(MailPrompt) And Not(PadPrompt) And Not(AutoExecPrompt) And Not(ResumePrompt);
	Temp1:=Temp1 And Not(DoorPrompt) And Not(ChatPrompt);
	Temp2:=(MailPrompt Or PadPrompt Or AutoExecPrompt Or ResumePrompt Or DoorPrompt Or ChatPrompt) And (ToCommandMode);
	CommandMode:=Temp1 Or Temp2;
End; (* Odredjuje da li je naredba za glavni komandni mod *)

Procedure Parser (s : String);
Var Temp,
		Rest,
		Options : String;
		Razmak,
		Duzina,
		Count 	:	Byte;
Begin
	If BFiles.Log Then BFiles.WriteAction2Log ('   '+s);
	If (Pos (':',s)=1) Or (Pos (';',s)=1) Or (Pos('`',s)=1) Then Exit;

	NormCaps:=s;

  ToCommandMode:=FALSE;
	If (Pos ('!',s)=1) Then Begin
		Uzvicnik:=TRUE;
		ToCommandMode:=TRUE;
		s:=Copy (s,2,Ord(s[0]));
	End;

	Razmak:=Pos (' ',s);
	Duzina:=Ord (s[0]);

	If Razmak>2 Then Begin
		Rest:=Copy (s,Razmak+1,Duzina);
		s   :=Copy (s,1,Razmak-1);
	End Else Rest:='';

	OriginalCommand:=Rest; (* da se spase capsovi kod komande *)

	s    := Misc.Upper (s);
	Rest := Misc.Upper (Rest);

	If (Rest<>'') Then Begin
		Razmak:=Pos (' ',Rest);
		Duzina:=Ord (Rest[0]);
		If Razmak>2 Then Begin
			Options:=Copy (Rest,Razmak+1,Duzina);
			Rest	 :=Copy (Rest,1,Razmak-1);
		End	Else Options:='';
	End Else Options:='';

	If CommandMode Then Begin
		Misc.CommandModeParser (s,rest,options);
		Exit;
	End;
	If (MailPrompt) 		And Not(ToCommandMode) Then Mail.MailModeParser (s,rest,options);
	If (PadPrompt)  		And Not(ToCommandMode) Then Pad.PadModeParser   (s,rest,options);
	If (AutoExecPrompt) And Not(ToCommandMode) Then AutoExec.AutoExecModeParser (s,rest,options);
	If (ResumePrompt)   And Not(ToCommandMode) Then Resume.Parser (s,rest,options);
	If (DoorPrompt) 		And Not(ToCommandMode) Then Door.DoorModeParser (s,rest,options);
	If (ChatPrompt)			And Not(ToCommandMode) Then Net.Chat (NormCaps);
End; (* Razlaze ulazni string na s,rest,options , predparser *)

Procedure Redirect;
Begin
	Assign (OutPut,'');
	ReWrite(OutPut);
End; (* Omogucava ANSI, usporava ispisi *)

Procedure StartSession;
Begin
	ChDir (GetEnv('SONIC_BBS'));
	Quit		:=	FALSE;
	Local		:=	FALSE;
	TimeOut	:=	FALSE;
	Ring		:=  FALSE;

	If Upper(ParamStr(1))='L' Then Local:=TRUE; (* Ne inicijalizuje modem *)
	Init;

	If Not(Local) Then Begin
		WriteLn ('Initializating modem...');
		Modem.InitModem;

		Repeat
			Modem.Terminal;

			If Misc.Ring Then
			Begin
					Modem.Answer;
					Login;
					Exit;
			End
				Else Begin
					BBegin.PrintScreen;
					Repeat
						Repeat

						Until KeyPressed;
					Until (BBegin.ProcessKey) Or Modem.Connected;
				End;

      If Not(Modem.Ring) and Not(Modem.Connected)
        Then Local:=Modem.Local
				Else Local:=False;

     Until (Ring and Modem.Connected) Or Local;
	End; (* Local = False *)

	ChDir ('f:\'); (* Daj ovdje substovan dir *)

	LogIn;
End; (* Prva procedura pri startovanju, dali je za lokal, provjera!? Ringa *)

Procedure TakeCommands;
Begin
	CheckBreak:=FALSE;
	SetCBreak(TRUE);
	Repeat
		Misc.Prompt;
		Misc.Command:=Modem.TakeCommand (Not(Misc.MesgOff));
		If Not(ChatPrompt) Then Modem.OutLn ('');
		Misc.Parser (Command);
		Modem.OutLn ('');
	Until (Misc.TimeOut) Or (Misc.Quit) Or (Not(Modem.Connected) And Not(Local));
	If Not(Modem.Local) And Modem.Connected Then Modem.HangUp;
	If Quit And Log Then BFiles.CloseLog;
	Net.SignOff;
End; (* Glavna petlja, traje dok nije timeout i nije izlaz *)


End.
