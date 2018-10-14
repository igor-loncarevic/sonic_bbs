{$F+,O+}

Unit	BBSBase;

INTERFACE

Uses
	TBase;

Var
	Dbf_File : DataObject;

Var
	UserRight : Integer;
	Base			:	String;

Procedure Create_Dbf;
Procedure Open_Dbf;
Procedure Close_Dbf;
Procedure Make_Dbf;
Function MakeBlanks (what : String) : String;
Procedure Add_Member (name,lastname,town,username,password,right:String);
Function IsPassword (username,password : String) : Boolean;
Function IsUser (username : String) : Boolean;
Procedure ChangePassword (password: String);
Procedure Kill_User (s : String);
Procedure ShowDatas (mode: Boolean;s: String);
Procedure NewBase;
Procedure DisplayBBSBase;
Procedure EditUser (s: String); (* UserEdit *)

IMPLEMENTATION

Uses
	ANSI,
	BFiles,
	Help,
	Modem,
	Red;


Procedure Create_Dbf;
Begin
	CreateDbFile (Base);
	New (Dbf_File,Init (Base));
End;

Procedure Open_Dbf;
Begin
	New( Dbf_File, Init(Base));
End;

Procedure Make_Dbf;
Begin
	With Dbf_File^ do begin
		ChangeField('NewField','NAME', 'C',15,0 ) ;
		AddField ('LASTNAME','C',15,0);
		AddField ('TOWN'    ,'C',15,0);
		AddField ('USERNAME','C',15,0);
		AddField ('PASSWORD','C',15,0);
		AddField ('RIGHT'   ,'C',15,0);
	End;
End;

Procedure Close_Dbf;
Begin
	Dispose (Dbf_File,Done);
End;

Procedure Add_Member (name,lastname,town,username,password,right:String);
Begin
	Open_Dbf;
	With Dbf_File^ do begin
		Replace ('NAME'    ,name);
		Replace ('LASTNAME',lastname);
		Replace ('TOWN'    ,town);
		Replace ('USERNAME',username);
		Replace ('PASSWORD',password);
		Replace ('RIGHT'   ,right);
		AddDbRec;
		Save;
	End;
	Close_Dbf;
End;

Function MakeBlanks (what : String) : String;
Var i,Len : byte;
Begin
	Len:=Ord(What[0]);
	If Len<15 then
		For	i:=Len to 14 do
			what:=what+' ';
	MakeBlanks:=What;
End;

Function TakeBlanks (what : String) : String;
Var i,Len : byte;
Begin
	i:=Pos (' ',what);
	what:=copy(what,1,i);
	TakeBlanks:=What;
End;

Function IsPassword (username,password : String) : Boolean;
Var
	records : LongInt;
	count		: LongInt;
	temp		:	String;
	p 			: Byte;
	i				:	Integer;
Begin
	username:=MakeBlanks(username);
	password:=MakeBlanks(password);
	count:=1;
	With Dbf_File^ do begin
		records:=RecCount+1;
		GoTop;
		While count<records do begin
			If FieldData('USERNAME')=username Then
				If FieldData('PASSWORD')=password Then
					Begin
						IsPassword:=TRUE;
						temp:=FieldData ('RIGHT');
						p:=Pos (' ',temp);
						temp:=Copy (temp,1,p-1);
						Val (temp,UserRight,i);
						Exit;
					End;
			NextRec;
			Inc (count);
		End; {While}
	End; {With}
	IsPassword:=FALSE;
End; {IsPassword}

Function IsUser (username : String) : Boolean;
Var
	count,records : LongInt;
Begin
	username:=MakeBlanks(username);
	count:=1;
	With Dbf_File^ do begin
		records:=RecCount+1;
		GoTop;
		While count<records do begin
			If FieldData('USERNAME')=username then begin
				IsUser:=TRUE;
				Exit;
			End;
			NextRec;
			Inc (count);
		End; {While}
	End; {With}
	IsUser:=FALSE;
End; {IsUser}

Procedure ChangePassword (password: String);
Begin
	With Dbf_File^ Do Begin
		Replace ('PASSWORD',password);
		Save;
	End;
End; {ChangePassword}


Function Lower (s : String):String;
Var	Len,
		count: Byte;
Begin
	Len:=Ord(s[0]);
	For	count:=1 to len do
		If s[count] In ['A'..'Z'] Then s[count]:=Chr(Ord(s[count])+32);
	Lower:=s;
End; {Lower}


Procedure Kill_User (s : String);
Begin
	s:=Lower(s);
	s:=MakeBlanks(s);
	Open_Dbf;
	With Dbf_File^ do begin
		If IsUser(s) Then Begin
				DbDelete;
				BFiles.WriteAction2Log ('-KILL user:'+s);
				Modem.OutLn ('User '+ANSI.BRIGHT+s+ANSI.NORMAL+' deleted from BBS.');
				Pack;
				Close_Dbf;
				Exit;
		End;
	End; {With}
	Modem.OutLn ('User does not exist.');
	Close_Dbf;
End; {Kill User}


Procedure ShowDatas (mode: Boolean;s: String);
	Procedure FinHeader;
	Begin
		Modem.OutLn ('Username         Name             LastName         Town');
		Modem.OutLn ('====================================================================');
	End;

	Procedure FinDatas;
	Var
		Line: String;
	Begin
		With Dbf_File^ Do Begin
			If Red.Redirect Then Line:=FieldData('USERNAME')
											Else Line:=ANSI.BRIGHT+FieldData('USERNAME')+ANSI.NORMAL;
			Line:=Line+'  '+FieldData('NAME')+'  '+FieldData('LASTNAME')+'  '+FieldData('TOWN');
			Modem.OutLn (Line);
		End;
	End;


	Procedure AllHeader;
	Begin
		Modem.OutLn ('Username       Name           LastName       Town           Password      Right');
		Modem.OutLn ('===============================================================================');
	End;

	Procedure AllDatas;
	Begin
		With Dbf_File^ Do Begin
			Modem.Out (ANSI.BRIGHT+FieldData('USERNAME')+ANSI.NORMAL);
			Modem.Out (FieldData('NAME'));
			Modem.Out (FieldData('LASTNAME'));
			Modem.Out (FieldData('TOWN'));
			Modem.Out ('<secret-key>   ');  (* kriptovati *)
			Modem.Out (TakeBlanks(FieldData('RIGHT')));
			Modem.OutLn ('');
		End;
	End;

Var
	count,
	records : LongInt;
	poz			: Byte;
Begin
	If Not(Red.CheckRed(s,'FINGER.LOG')) Then Exit;
	Red.HandleSign (s);

	poz:=Pos('*',s);
	If Poz>0 then	s:=Copy(s,1,poz-1);
	s:=Lower (s);
	count:=1;
	Open_Dbf;
	If mode Then FinHeader
					Else AllHeader;  (* TRUE za finger, FALSE za all *)
	With Dbf_File^ do begin
		records:=RecCount+1;
		GoTop;
		While count<records do begin
			Case mode of
				TRUE  : If Pos(s,FieldData('USERNAME'))=1 Then FinDatas;
				FALSE : If Pos(s,FieldData('USERNAME'))=1 Then AllDatas;
			end;
			NextRec;
			Inc(count);
		End;
	End; {With}
	Close_Dbf;
	Red.HandleRedirect;
End;

Procedure NewBase;
Var
	temp	:	String;
Begin
	Modem.Out ('Password for command: ');
	Modem.Hide:=TRUE;
	temp:=Modem.TakeCommand (FALSE);
	Modem.Hide:=FALSE;
	If Not(temp='BackDoorTemp') Then Begin
		Modem.OutLn (#13#10+'Wrong password, access denied.');
		BFiles.WriteAction2Log ('-NEW USER SYSTEM failed on password: '+temp);
		Exit;
	End;

	Create_Dbf;
	Make_Dbf;
	Close_Dbf;
	BBSBase.Add_Member ('Igor','Loncarevic','Town','anubis','secretpassword','128');
	Modem.OutLn (#7+'Done.');
	BFiles.WriteAction2Log ('-NEW USER SYSTEM created.');
End;

Procedure DisplayBBSBase;
Begin
	Open_Dbf;
	Dbf_File^.DisplayFields;
	Close_Dbf;
End;

Procedure EditUser (s: String); (* UserEdit *)

	Procedure SetName (ss: String);
	Var
		temp: String;
	Begin
		Modem.Out ('Change '+ss+' to:');
		temp:=Modem.TakeCommand (FALSE);
		If temp='' Then Exit;
		Dbf_File^.Replace(ss,temp);
	End;

Begin
	Open_Dbf;
	s:=Lower(s);
	If Not(IsUser(s)) Then Begin
		Modem.OutLn ('User '+s+' does not exist.');
		Close_Dbf;
		Exit;
	End;

	With Dbf_File^ Do Begin
			Modem.OutLn ('EditUser: '+ANSI.BRIGHT+FieldData('USERNAME')+ANSI.NORMAL);

			Modem.OutLn (#13'Name: '+FieldData('NAME'));
			SetName ('name');

			Modem.OutLn (#13#13+'Last name: '+FieldData('LASTNAME'));
			SetName ('lastname');

			Modem.OutLn (#13+'Town: '+FieldData('TOWN'));
			SetName ('town');

			Modem.OutLn (#13#13+'Password: <secret-key>');  (* kriptovati *)
			SetName ('password');

			Modem.OutLn (#13#13+'Rights: '+TakeBlanks(FieldData('RIGHT')));
			SetName ('right');

			Modem.OutLn ('');
	End;

	Close_Dbf;
End;

End.