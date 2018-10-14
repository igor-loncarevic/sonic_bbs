{$F+,O+}

Unit	BigBase;

INTERFACE

Var
	Username,
	BigBaseFile 		: String;
	FirstCallToday	: Boolean;
	Right,
	RestMinutes 		: Integer;

Function GetFirstMail							: LongInt;
Function BIsUser 									: Boolean;
Function ShowFieldStr (s: String)	: String;

Procedure Create_Dbf;
Procedure Open_Dbf;
Procedure Make_Dbf;
Procedure Close_Dbf;
Procedure MakeUser;
Procedure Reset_Dbf;

Procedure SetArchiver;
Procedure SetPadNumber;
Procedure SetFirstMail 					(Long: LongInt);
Procedure SetLastDateAndTime;
Procedure ShowLastDateAndTime;
Procedure IncrementField				(s: String);
Procedure ShowUserStat 					(s,options: String);
Procedure DecrementDayTime;
Procedure IncrementOnLineTime;
Procedure Kill_User 						(s: String);
Procedure SetField 							(what,s: String);
Procedure ShowSet 							(s: String);
Procedure SetCmd 								(s: String); (* SET naredba *)
Procedure Create_New_Base;
Procedure DisplayBigBase;

IMPLEMENTATION

Uses
	ANSI,
	BBSBase,
	BFiles,
	BTimer,
	Config,
	CRT,
	DbDate,
	Help,
	Misc,
	Modem,
	Pad,
	Red,
	TBase;

Var
	Dbf_File 	: DataObject;
	No				: LongInt;

Function GiveTotalDayTime : Real;
Var time 			: Real;
		TotalDay 	: String;
Begin
	If Right=Config.GUEST 				Then time:=Config.GuestTime
	Else If Right=Config.Normal 	Then time:=Config.NormalTime
	Else If Right=Config.Benefit 	Then time:=Config.BenefitTime
	Else If Right=Config.FileAdm 	Then time:=Config.FileAdmTime
	Else If Right=Config.SysOp 		Then time:=Config.SysOpTime
	Else Modem.OutLn ('BigBase.GiveTotalDay ne postoji user');
	GiveTotalDayTime:=time;(*TotalDay;*)
End; {F|GiveTotalDayTime : String}


Procedure Create_Dbf;
Begin
	CreateDbFile (BigBaseFile);
	New (Dbf_File,Init (BigBaseFile) );
End;


Procedure Open_Dbf;
Begin
	New( Dbf_File, Init(BigBaseFile) );
End;

Procedure Close_Dbf;
Begin
	Dispose (Dbf_File,Done);
End;


Procedure Make_Dbf;
Begin
	With Dbf_File^ do begin
		ChangeField('NewField',
							'USERNAME', 'C',15,0);
		AddField ('FIRM'		 ,'C',40,0);
		AddField ('NO_DL'		 ,'N', 4,0);
		AddField ('NO_UL'		 ,'N', 4,0);
		AddField ('KB_DL'		 ,'N', 6,0);
		AddField ('KB_UL'		 ,'N', 6,0);
		AddField ('CONNECT'  ,'N', 4,0);
		AddField ('BADPASS'  ,'N', 3,0);
		AddField ('PROTOCOL' ,'N', 1,0);
		AddField ('ANSI'     ,'N', 1,0);
		AddField ('LASTDATE' ,'D', 0,0);
		AddField ('LASTTIME' ,'C', 8,0);
		AddField ('OLR'		   ,'C', 3,0);
		AddField ('FIRSTDATE','D', 0,0);
		AddField ('NO_MAIL'  ,'N', 5,0);
		AddField ('NO_CONF'  ,'N', 5,0);
		AddField ('TOTALDAY' ,'N', 3,0);
		AddField ('RESTTODAY','N', 3,0);
		AddField ('ONLINE'   ,'N', 6,0);
		AddField ('PAD_NO'   ,'N', 4,0);
		AddField ('NUMBER'   ,'N', 5,0);
		AddField ('ARCHIVER' ,'C', 3,0);
		AddField ('WIDTH'    ,'C', 2,0);
		AddField ('FIRSTMAIL','N', 6,0);  (* prva poruka koja je za usera *)
	End;
End;


(*-----------------------------------------------------------------------*)

Function UserNumber : Real;  
Var	TotalUsers : LongInt;
Begin
	With Dbf_File^ do
		TotalUsers:=RecCount;
	Inc (TotalUsers);
	UserNumber:=TotalUsers;
End; (* Vraca broj broj recordsa + 1 *)

Function BIsUser : Boolean;
Var
	count,records : LongInt;
Begin
	username:=BBSBase.MakeBlanks(username);
	count:=1;
	With Dbf_File^ do begin
		records:=RecCount+1;
		GoTop;
		While count<records do begin
			If FieldData('USERNAME')=username then begin
				BIsUser:=TRUE;
				No:=RecNo;
				Exit;
			End;
			NextRec;
			Inc (count);
		End; {While}
	End; {With}
	BIsUser:=FALSE;
End; {F||BIsUser}


Procedure MakeUser;
Var DateField 	: String;
		TimeString 	:	String;
		SysDate			: Date;
Begin
	DbDate.Today (SysDate);
	DateField := DbDate.DateToFormat (SysDate);
	TimeString:= Misc.Stat ('TIME');
	With Dbf_File^ do begin
			Replace  ('USERNAME' ,Username);
			Replace  ('FIRM'		 ,'');
			ReplNum  ('NUMBER'   ,UserNumber);
			Replace  ('NO_DL'		 ,'0');
			Replace  ('NO_UL'		 ,'0');
			Replace  ('KB_DL'		 ,'0');
			Replace  ('KB_UL'		 ,'0');
			Replace  ('CONNECT'  ,'1');
			Replace  ('BADPASS'  ,'0');
			Replace  ('PROTOCOL' ,'0');
			Replace  ('ANSI'     ,'0');
			Replace  ('LASTDATE' ,DateField);
			Replace  ('LASTTIME' ,TimeString);
			Replace  ('OLR'		   ,'None');
			Replace  ('FIRSTDATE',DateField);
			Replace  ('NO_MAIL'  ,'0');
			Replace  ('NO_CONF'  ,'0');
			ReplNum  ('TOTALDAY' ,GiveTotalDayTime);
			ReplNum  ('RESTTODAY',GiveTotalDayTime);
			Replace  ('ONLINE'   ,'0');
			Replace  ('PAD_NO'   ,'0');
			Replace  ('ARCHIVER' ,'ZIP');
			Replace  ('WIDTH'    ,'24');
			Replace  ('FIRSTMAIL','0');
			AddDbRec;
			Save;
	End;
End; {P|MakeUser}


Procedure SetArchiver;
Var
	Temp: String;
Begin
	With Dbf_File^ do Begin
		GetDbRec(No);
		Temp:=FieldData ('ARCHIVER');
	End;

	If 			Temp='ZIP' Then Pad.Archiver:=Config.ZIPArchiver
	else If Temp='ARJ' Then Pad.Archiver:=Config.ARJArchiver
	else If Temp='LHA' Then Pad.Archiver:=Config.LHAArchiver;
End;


Procedure SetPadNumber;
Var
	r: Real;
	i: Integer;
	temp: String;
Begin
	Open_Dbf;
	Dbf_File^.GetDbRec(No);
	r:=Dbf_File^.Increment('PAD_NO',1);

	Close_Dbf;
	i:=Trunc(r);
	Str (i:5,Temp);
	For i:=1 to length(temp) do
		if temp[i]=' ' then temp[i]:='0';

	Pad.PadNumber:=Temp;
End; {SetPadNumber}

Procedure IncrementField(s: String);
Var	r: real;
Begin
	With Dbf_File^ do begin
		GetDbRec(No);
		r:=Increment(s,1);
		ReplNum(s, r) ;
		Save;
	End;
End; (* Povecava numericki field za 1 *)

Procedure SetFirstMail (Long: LongInt);
Begin
	Open_Dbf;
	With Dbf_File^ Do Begin
		GetDbRec (No);
		ReplNum ('FIRSTMAIL',Long);
		Save;
	End;
	Close_Dbf;
End; (* Setuje prvu poruku poslanu korisniku *)

Function GetFirstMail: LongInt;
	Procedure Take (var s: string);
	Begin
		While Pos(' ',s)>0 do
			Delete(s,1,1);
	End; (* brise blanko znakove iz stringa *)

Var
	s: String;
	Long: LongInt;
	Code: Integer;
Begin
	Open_Dbf;
	With Dbf_File^ do begin
		GetDbRec (No);
		s:=FieldData ('FIRSTMAIL');
		Take (s);
		If s[1]='0' Then GetFirstMail:=0
		Else Begin
			Val (s,Long,Code);
			GetFirstMail:=Long;
		End;
	End;
	Close_Dbf;
End; (* Vraca pocetni broj maila *)


Procedure SetLastDateAndTime;
Var TimeString 	:	String;
		SysDate			: Date;
Begin
	DbDate.Today (SysDate);
	TimeString:=Misc.Stat ('TIME');
	With Dbf_File^ Do Begin
		GetDbRec(No);
		ReplDate ('LASTDATE',SysDate);
		Replace  ('LASTTIME',TimeString);
		Save;
	End;
End; {P|SetLastDateAndTime}

Procedure ShowLastDateAndTime;
Var DateField,
		TimeString,
		Temp				: String;
		SysDate			: Date;
		r						: Real;
		Code        : Integer;
Begin
	With Dbf_File^ Do Begin
		GetDbRec(No);
		DateField  :=FieldData ('LASTDATE');
		TimeString:= FieldData ('LASTTIME');
		DbDate.Today (SysDate);
		Temp:=DbDate.DateToFormat (SysDate);
		If DateField=Temp Then FirstCallToday:=FALSE
											Else FirstCallToday:=TRUE;
		If FirstCallToday Then Begin
			ReplNum ('RESTTODAY',GiveTotalDayTime);
			Save;
		End;
		temp:=FieldData('RESTTODAY');
		Val (temp,r,code);
		RestMinutes:=Trunc(r);
		Modem.OutLn ('Last call on '+DateField+', at '+TimeString+'.');
		Modem.OutLn ('For this call you have '+ANSI.BRIGHT+Temp+ANSI.NORMAL+' minute(s).');

		Temp:=FieldData ('WIDTH');
		Val (Temp,BFiles.Width,Code);
	End;
End; {P|ShowLastDateAndTime}

Procedure DecrementDayTime;
Var r : Real;
Begin
	Open_Dbf;
	With Dbf_File^ Do Begin
		GetDbRec(No);
		r:=RestMinutes-BTimer.OnLine;
		ReplNum('RESTTODAY',r);
		Save;
	End;
	Close_Dbf;
End; {P|DecrementDayTime}

Procedure IncrementOnLineTime;
Var r : Real;
Begin
	Open_Dbf;
	With Dbf_File^ Do Begin
		GetDbRec(No);
		r:=Increment('ONLINE',BTimer.OnLine);
		ReplNum('ONLINE',r);
		Save;
	End;
	Close_Dbf;
End; {P|IncrementOnLineTime}

Function ShowFieldStr ( s : String) : String;
Var temp : String;
Begin
	Open_Dbf;
	With Dbf_File^ Do Begin
		GetDbRec(No);
		Temp:=FieldData (s);
	End;
	Close_Dbf;

	If s='ANSI' Then Begin
		If Temp='0' Then Temp:='No'
		Else If Temp='1' Then Temp:='Yes';
	End
	Else If s='PROTOCOL' Then Begin
		If Temp='1' Then Temp:='ZModem'
		Else If Temp='2' Then Temp:='Bi-Modem'
		Else Temp:='None';
	End;

	ShowFieldStr:=Temp;
End; {F|ShowFieldStr : String}

Procedure ShowUserStat (s,options : String);
Var BackupRealUser,
		temp 						: String;
		TempNo					: LongInt;
Begin
	s:=Lower(s);
	BackupRealUser:=Username;
	If Not(Pos('>',s)>0) Then Username:=s;
	Open_Dbf;

	TempNo:=No;
	If Not(BIsUser) Then Begin
		Modem.OutLn ('User does not exist in BigBase.');
		Close_Dbf;
		Username:=BackupRealUser;
		Exit;
	End;
	No:=TempNo;

	With Dbf_File^ do begin
		If Not(Red.CheckRed(s+Options,'STAT.LOG')) Then Exit;
		temp:=FieldData('ANSI');
		If temp='1' Then Temp:='Yes'
								Else Temp:='No';
		Modem.OutLn ('================== '+ANSI.BRIGHT+'User statistics'+ANSI.NORMAL+' ====================');
		Modem.OutLn ('    Username: '+Username+'        Number: '+FieldData('NUMBER'));
		Modem.OutLn ('     Company: '+FieldData('FIRM'));
		Modem.OutLn (' First login: '+FieldData('FIRSTDATE'));
		Modem.OutLn ('-------------------------------------------------------');
		Modem.OutLn ('Number of DL: '+FieldData('NO_DL')+'   .... kilobytes: '+FieldData('KB_DL'));
		Modem.OutLn ('Number of UL: '+FieldData('NO_UL')+'   .... kilobytes: '+FieldData('KB_UL'));
		Modem.OutLn ('Mail message: '+FieldData('NO_MAIL'));
		Modem.OutLn ('Conf message: '+FieldData('NO_CONF'));
		Modem.OutLn ('-------------------------------------------------------');
		Modem.OutLn ('Bad password: '+FieldData('BADPASS')+' attempt');
		Modem.OutLn (' Connections: '+FieldData('CONNECT'));
		Modem.OutLn ('Total Online: '+FieldData('ONLINE')+' min.');
		Modem.OutLn ('Time per Day: '+FieldData('TOTALDAY')+'    .... rest time: '+FieldData('RESTTODAY'));
		Modem.OutLn ('-------------------------------------------------------');
		Modem.OutLn ('         OLR: '+FieldData('OLR')+'         Archiver: '+FieldData('ARCHIVER'));
		Modem.OutLn ('       Width: '+FieldData('WIDTH')+'              ANSI: '+Temp);
	End;
	Close_Dbf;
		Modem.OutLn ('    Protocol: '+ShowFieldStr('PROTOCOL'));
		Modem.OutLn ('-------------------------------------------------------');
	Username:=BackupRealUser;
	Red.HandleRedirect;
End; {ShowUserStat}

Procedure Kill_User (s : String);
Var BackupRealUser,
		temp 						: String;
Begin
	BackupRealUser:=Username;
	s:=Misc.Lower(s);
	Username:=s;
	Open_Dbf;
	If BIsUser Then
		With Dbf_File^ do begin
			DbDelete;
			Modem.OutLn ('User deleted from BigBase >> '+s);
			Pack;
			Close_Dbf;
			Username:=BackupRealUser;
			Exit;
		End;
	Username:=BackupRealUser;
  Modem.OutLn ('User not in BigBase.');
	Close_Dbf;
End; {Kill User}

Procedure SetField (what,s : String);
Begin
	Open_Dbf;
	With Dbf_File^ do begin
		GetDbRec(No);
		Replace (what,s);
		Save;
	End;
	SetArchiver;
	Close_Dbf;
End; {P|SetField}


Procedure ShowSet (s: String);
Var
	Temp 	:	String;
Begin
	If Not(Red.CheckRed (s,'SET.LOG')) Then Exit;
	Modem.OutLn ('========================');
	Temp:='Username: '+ANSI.BRIGHT+username+ANSI.NORMAL;  Modem.OutLn (Temp);
	Temp:='COmpany : '+BigBase.ShowFieldStr ('FIRM');			Modem.OutLn (Temp);
	Temp:='ANSI    : '+BigBase.ShowFieldStr ('ANSI');			Modem.OutLn (Temp);
	Temp:='PROtocol: '+BigBase.ShowFieldStr ('PROTOCOL'); Modem.OutLn (Temp);
	Temp:='OLR     : '+BigBase.ShowFieldStr ('OLR');      Modem.OutLn (Temp);
	Temp:='ARChiver: '+BigBase.ShowFieldStr ('ARCHIVER'); Modem.OutLn (Temp);
	Temp:='WIdth   : '+BigBase.ShowFieldStr ('WIDTH');    Modem.OutLn (Temp);
	Modem.OutLn ('------------------------');
	Red.HandleRedirect;
End; {P|ShowSet}


Function Choosing : Char;
Var
	Ch: Char;
Begin
	Modem.Out (Enter+' Reply: ');
	Repeat
		Repeat Until KeyPressed;
		Ch:=ReadKey;
		Ch:=UpCase (Ch);
		If (Ch In ['1','2','3','4','5','H','S','Z','B','A','L','Z','Y','N']) Then Begin
			Choosing:=Ch;
			Modem.Out (Ch);
			Exit;
		End;
	Until False;
End;

Procedure SetANSI;
Var
	Ch : Char;
Begin
	Modem.OutLn ('Do you want ANSI text?');
	Modem.OutLn ('     1.....[Y]es ');
	Modem.OutLn ('     2.....[N]o  ');

	Case Choosing Of
		'1','Y' : BigBase.SetField ('ANSI','1');
		'2','N' : BigBase.SetField ('ANSI','0');
	End;
End; {P|SetAnsi}


Procedure SetFIRM;
Var
	Temp : String;
Begin
	Temp:='';
	Modem.Out (#10+'Name of company: ');
	Temp:=Modem.TakeCommand (FALSE);

	If Not(Temp='')	Then BigBase.SetField ('FIRM',temp)
									Else Modem.OutLn (#10+'Name was not changed.');
End; {P|SetFIRM}


Procedure SetPROTOCOL;
Var
	Ch : Char;
Begin
	Modem.OutLn ('Choose file transfer protocol:');
	Modem.OutLn ('     1.....[Z]Modem');
	Modem.OutLn ('     2.....[B]iModem');

	Case Choosing Of
		'1','Z' : BigBase.SetField ('PROTOCOL','1');
		'2','B' : BigBase.SetField ('PROTOCOL','2');
	End;
End; {P|SetProtocol}


Procedure SetOLR;
Var Ch : Char;

Begin
	Modem.Out (ANSI.BRIGHT);
	Modem.OutLn ('Choose Off-Line Reader:');
	Modem.Out (ANSI.NORMAL);
	Modem.OutLn ('     1.....[S]OR  (Sezam Off-Line Reader)');
	Modem.OutLn ('     2.....T[H]OR (Hobbiton Off-Line Reader)');
	Modem.OutLn ('     3.....[N]one');

	Case Choosing Of
		'1','S'	: BigBase.SetField ('OLR','SOR');
		'2','H' : BigBase.SetField ('OLR','HOR');
		'3','N' : BigBase.SetField ('OLR','QWK');
	End;
End; {P|SetOLR}

Procedure SetARC;
Var Ch : Char;

Begin
	Modem.Out (ANSI.BRIGHT);
	Modem.OutLn ('Choose Off-Line Reader:');
	Modem.Out (ANSI.NORMAL);
	Modem.OutLn ('     1.....ZIP');
	Modem.OutLn ('     2.....ARJ');
	Modem.OutLn ('     3.....LHA');

	Case Choosing Of
		'1','Z' : BigBase.SetField ('ARCHIVER','ZIP');
		'2','A' : BigBase.SetField ('ARCHIVER','ARJ');
		'3','L'	: BigBase.SetField ('ARCHIVER','LHA');
	End;
End; {P|SetARC}

Procedure SetPASS;
Var
	Old,
	New1,New2 : String;
Begin
	Modem.Hide:=TRUE;

	Modem.Out ('Type your current password: ');
	Old:=Modem.TakeCommand (FALSE);

	BBSBase.Open_Dbf;
	If Not(BBSBase.IsPassword (username,old)) Then Begin
		Modem.OutLn (Enter+'Wrong password.');
		BBSBase.Close_Dbf;
		Modem.Hide:=False;
		Exit;
	End;

	Modem.Out (Enter+'Type new password: ');
	New1:=Modem.TakeCommand (FALSE);

	Modem.Out (Enter+'     Please again: ');
	New2:=Modem.TakeCommand (FALSE);

	If New1=New2 	Then BBSBase.ChangePassword (new1)
								Else Modem.OutLn (Enter+Enter+'Passwords are different.');

	BBSBase.Close_Dbf;

	Modem.Hide:=FALSE;
End; {SetPASS}

Procedure SetWIDTH;
Var
	Temp : String;
	Len	 : Byte Absolute Temp;
	Code : Integer;
Begin
	Modem.Out ('Set width (24 normal): ');
	Temp:=Modem.TakeCommand (FALSE);
	Val (Temp,BFiles.Width,Code);
	If (Code<>0) Or ((Len>2) Or (Len<1)) Or Not((Temp[1] In ['1'..'9']) And (Temp[2] In ['0'..'9'])) Then Begin
		Modem.OutLn ('Invalid number. (10-99)');
		Exit;
	End;

	BigBase.SetField ('WIDTH',Temp);
End;


Procedure SetCmd (s : String); (* SET naredba *)
Var Ch : Char;

Begin
	If Misc.ToHelp (s) Then Begin
		Help.On ('Set');
		Exit;
	End
	Else If (s='') Or (Pos('>',s)>0) Then Begin
		ShowSet (s);
		Exit;
	End
	
	Else If (s='OLR') 		 Or (s='READER')						Then SetOLR
	Else If (s='ARCHIVER') Or (s='ARC') 							Then SetARC
	Else If (s='PASSWORD') Or (s='PAS')								Then SetPASS
	Else If (s='WIDTH')		 Or (s='WI')								Then SetWIDTH
	Else If (s='COMPANY')  Or (s='CO') Or (s='FIRM')	Then SetFIRM
	Else If (s='PROTOCOL') Or (s='FTP') Or (s='PRO') 	Then SetPROTOCOL
	Else If (s='ANSI') Or (s='TERM') Or (s='TERMINAL')Then SetANSI
	Else Modem.OutLn (s+' don''t exist.');
End; {P:Set}

Procedure Create_New_Base;
Var
	temp: String;
Begin
	Modem.Out ('Password for command: ');
	Modem.Hide:=TRUE;
	temp:=Modem.TakeCommand(FALSE);
	Modem.Hide:=FALSE;
	If Not(temp='SuicidaL') Then Begin
		Modem.OutLn (Enter+'Wrong password, access denied.');
		BFiles.WriteAction2Log ('-NEW BASE SYSTEM failed on password by '+Misc.Username+'['+temp+']');
		Exit;
	End;
	Create_dbf;
	Make_Dbf;
	Close_dbf;
	BFiles.WriteAction2Log ('-NEW BASE SYSTEM created by '+Misc.Username);
	Modem.OutLn (Enter+#7'Done.');
End; (* Brise staru i kreira novu bigbase.dbf *)

Procedure Reset_Dbf;
Begin
	Open_Dbf;
	Dbf_File^.DbReset;
	Close_Dbf;
End;

Procedure DisplayBigBase;
Begin
	Open_Dbf;
	Dbf_File^.DisplayFields;
	Close_Dbf;
End;


End.
