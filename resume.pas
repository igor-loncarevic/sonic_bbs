Unit	Resume;

INTERFACE

Var
	ResumeDir,
	UserName	:	String;

Function DefineUserFile (s:String): String;
Procedure Parser (s,rest,options: String);

IMPLEMENTATION

Uses
	ANSI,
	BBSBase,
	BEditor,
	BFiles,
	Help,
	Misc,
	Modem,
	Net,
	Red,
	SysOp;

Const
	Quick=1;    (* Modovi za citanje resume-a *)
	Text=2;     (* 1 samo zaglavlje, 2 samo text ,3 oboje *)
	Full=3;


Function DefineUserFile (s:String): String;
Var
	Len,
	Count : Byte;
Begin
	Len:=Ord(s[0]);
	If (Len>8) Then Begin
		s:=Copy(s,1,8);
		Len:=8;
	End;

	Count:=1;
	While Count<=Len do
		Case s[Count] Of
			'.' : s[Count]:='-';
			Else Inc(Count);
		End;

	DefineUserFile:=s+'.BRF';
End; (* Pretvara username u prihvatljivi file name *)


Function Exist (s: String): Boolean;
Begin
	Exist:=BFiles.FileExists (ResumeDir+s);
End; (* Postoji li rezime za korisnika *)

Procedure Show (s:String);
Begin
	If Exist(s) Then BFiles.Show (ResumeDir+s);
	Modem.OutLn ('---------------------------------');
End; (* Prikazuje rezime korisnika *)

Procedure View (s,options : String;mode: Byte);
Var name,
		ri: String;
Begin
	If s='' Then Begin
		Modem.OutLn ('You must specifie username.');
		Exit;
	End;
	Net.SetWhere ('Resume Read');
	name:=DefineUserFile(s);
	s:=Lower(s);
	s:=MakeBlanks(s);
	Open_Dbf;
	With Dbf_File^ do begin
		If IsUser(s) then begin
			If Not(Red.CheckRed(Options,'RESUME.LOG')) Then Exit;
			If (mode=full) Or (mode=quick) Then Begin
				If FieldData('RIGHT')=MakeBlanks('2')  Then ri:=('Normal User');
				If FieldData('RIGHT')=MakeBlanks('4')  Then ri:=('Benefit User');
				If FieldData('RIGHT')=MakeBlanks('8')  Then ri:=('File Administrator');
				If FieldData('RIGHT')=MakeBlanks('128')Then ri:=('System Operator');
				Modem.OutLn ('=================================');
				Modem.OutLn ('Username: '+ANSI.BRIGHT+FieldData('USERNAME')+ANSI.NORMAL);
				Modem.OutLn ('    Name: '+FieldData('NAME')    );
				Modem.OutLn ('Lastname: '+FieldData('LASTNAME'));
				Modem.OutLn ('    Town: '+FieldData('TOWN')    );
				Modem.OutLn ('  Rights: '+ri                   );
				Modem.OutLn ('---------------------------------');
			End;
		End;
	End;
	Close_Dbf;
	If (Mode=Full) Or (Mode=Text) Then Show (name);
	Red.HandleRedirect;
	Net.SetWhere ('Sonic');
end; {Resume}


Procedure Edit;                                                               
Begin
	If Modem.Local Then SysOp.Shell ('q '+ResumeDir+Resume.UserName)
		Else BEditor.Edit (ResumeDir+Resume.UserName);
End;


Procedure Parser (s,rest,options: String);
Begin
	If (s='?') Or (s='HELP') Then BFiles.Show (BFiles.ResumeHelpFile)
	else if (s='CLS')  	Then Misc.CLS (rest)
	else if (s='TEXT')  Or (s='TE') Then View (rest,options,Text)
	else if (s='QUICK') Or (s='QU') Then View (rest,options,Quick)
	else if (s='EDIT')  Or (s='ED') Then Edit
	else if (s='SHOW')  Or (s='SH') Or (s='READ') Or (s='RE') Then View (rest,options,Full)
	else if (s='EXIT') 	Or (s='..') Or (s='EX')   Or (s='\')  Then
	Begin
		Misc.ResumePrompt:=FALSE;
		Net.SetWhere ('Sonic');
	End
	else If (s<>'') Then Modem.OutLn ('Unknown Resume command "'+s+'", type ? for Help');
End; (* Parser *)

End.

---------------------------------------------------------
