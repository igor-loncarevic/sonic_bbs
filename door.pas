{$O+,F+}

Unit	Door;

INTERFACE

Var
	BBSPath : String;

Procedure MakeDoorInfo (Username: String);
Procedure DoorModeParser (s,rest,options: String);

IMPLEMENTATION

Uses
	BFiles,
	Misc,
	Modem,
	Net;

Procedure MakeDoorInfo (Username: String);
Var
	f:	Text;
Begin
	Assign (f,BBSPath+'\DORINFO1.DEF');
	ReWrite (f);
	WriteLn (f,'Sonic BBS');
	WriteLn (f,'Igor');
	WriteLn (f,'Loncarevic');
	WriteLn (f,'COM2:');
	WriteLn (f,'2400 BAUD,N,8,1');
	WriteLn (f,'0');
	WriteLn (f,Username);
	WriteLn (f,'');
	WriteLn (f,'');
	WriteLn (f,'1');
	WriteLn (f,'0');
	WriteLn (f,'19');
	Close (f);
End;

Procedure Start (which: String);
Begin
	MakeDoorInfo (Misc.Username);
	If (which='TETRIS') Then Begin
		If Not(Local) Then Misc.Execute ('/C '+BBSPath+'\TETRIS.BAT')
									Else Misc.Execute ('/C '+BBSPath+'\STACK''EM\LOCAL.BAT');
	End;
End;


Procedure DoorModeParser (s,rest,options: String);
Begin
	If (s='?') Or (s='HELP') Then BFiles.Show (BFiles.DoorList)
	else if (s='TETRIS') Or (s='TET') Then Door.Start ('TETRIS')
	else if (s='EX') Or (s='..') Or (s='EXIT') Or (s='\') Then
	Begin
		Misc.DoorPrompt:=FALSE;
		Net.SetWhere ('Sonic');
	End
	else If (s<>'') Then Modem.OutLn ('Unknown Door name "'+s+'", ? for list od Doors');
End;



End.

