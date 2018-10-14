{$O+,F+}

Unit	SysOp;

INTERFACE

Var
	MemFile : String;

Procedure DOS_Memory 	(s: String);
Procedure Shell 			(s: String);
Procedure NewUser     (s: String; new: Boolean);
Procedure KillUser 		(s: String);
Procedure All 				(s: String);

IMPLEMENTATION

Uses
	BBSBase,
	BFiles,
	BigBase,
	BTimer,
	Help,
	Mail,
	Misc,
	Modem,
	Net;


Procedure DOS_Memory (s : String);
Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Mem');
		Exit;
	End;

	If Misc.Execute('/C '+'MEM '+s+' > '+MemFile)
		Then BFiles.Show (MemFile);
End;

Procedure Shell (s : String);
Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Shell');
		Exit;
	End;

	Net.SetWhere ('DOS');
	If s<>'' Then s:='/C '+s;
	If Not(Misc.Execute (s)) Then Modem.OutLn ('Could not execute Shell. (probably memory)')
		 Else Modem.OutLn ('[Back in bbs...]'+#7);
	Net.SetWhere ('Sonic');
End;

Procedure NewUser (s: String; new: Boolean);
Var username,
		name,
		lastname,
		town,
		password,
		verify,
		right,
		Temp		 : String;

Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('New');
		Exit;
	End;

	Repeat
		
		Modem.Out (Enter+'Username  : ');
		Username:=Modem.TakeCommand(FALSE);
		username:=lower(username);

    Modem.Out (Enter+'First name: ');
		Name:=Modem.TakeCommand (FALSE);

		Modem.Out (Enter+'Last name : ');
		LastName:=Modem.TakeCommand(FALSE);


		Modem.Out (Enter+'Town      : ');
		Town:=Modem.TakeCommand(FALSE);

		Repeat
			Modem.Hide:=TRUE;
			 Modem.Out (Enter+'       Password: ');Password:=Modem.TakeCommand(FALSE);
			 Modem.Out (Enter+'Verify password: ');Verify:=Modem.TakeCommand(FALSE);
			Modem.Hide:=FALSE;
		Until Password=Verify;

		If New Then Right:='2'
		Else Begin
			Modem.Out (Enter+'Right: ');
			Right:=Modem.TakeCommand(FALSE);
		End;

		Modem.OutLn (Enter+Enter+'Username: '+username);
		Modem.OutLn ('    Name: '+name+' '+lastname);
		Modem.OutLn ('    Town: '+town);

	 Until Modem.Rest ('Corretly writen');

	BBSBase.Add_Member (name,lastname,town,username,password,right);

	BFiles.WriteAction2Log ('-NEW user:'+username+' created by '+Misc.Username);
	Temp:=Misc.Username;

	BigBase.Open_Dbf;
	BigBase.Username:=username;
	BigBase.MakeUser;
	BigBase.Close_Dbf;

	Mail.Username:='anubis';
	Mail.ToNew (username);

	Mail.Username:=Temp;
	BigBase.Username:=Temp;
End; {New}


Procedure KillUser (s : String);
Begin
	If Misc.ToHelp(s) Then Begin
		Help.On ('Kill');
		Exit;
	End;

	If Modem.Rest ('Kill user') Then Begin
		BBSBase.Kill_User (s);
		BigBase.Kill_User (s);
	End;
End; {Kill User}

Procedure All (s : String);
Begin
	If Misc.ToHelp(s) Then Help.On ('All')
										Else BBSBase.ShowDatas (FALSE,s);
End;

End.