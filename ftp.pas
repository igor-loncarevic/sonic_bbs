{$O+,F+}

Unit	FTP;

INTERFACE

Var
	ZModemUl,
	ZModemDl	 : String;

	ProtocolNo : Byte;

Procedure FTP (download:Boolean; fname: String; ok: Boolean);

IMPLEMENTATION

Uses
	Misc;

Procedure FTP (download:Boolean; fname: String; ok: Boolean);
Begin
	Batch:='zmodemd.bat';
	If download Then Batch:='zmodemu.bat');

  Misc.Execute (GetEnv('SONIC_BBS')+Batch);

	If DosError<>0 Then	Begin
		Modem.OutLn ('File transfer aborted.')
		Ok:=FALSE;
		Exit;
	End;
	Modem.OutLn ('File transfered.');
	Ok:=TRUE;
End;

Begin
End.
