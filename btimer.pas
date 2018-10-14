Unit 	BTimer;

INTERFACE

Var
	LogOutTime,
	LogInTime,
	Current,
	time		 		: LongInt;
	UserRight		: Integer;

Procedure DefineTime;
Function IsTimeOut 	: Boolean;
Procedure GiveTime (min : Integer);
Procedure TakeTime (min : Integer);
Function OnLine 		: LongInt;  (* Vraca koliko je minuta user on *)
Function RestOnLine : LongInt;  (* Jos koliko min moze biti on *)

IMPLEMENTATION

Uses
	BigBase,
	Timer,
	Config;

Procedure Init;
Begin
	If UserRight=Config.GUEST 				Then time:=Config.GuestTime
	Else If UserRight=Config.Normal 	Then time:=Config.NormalTime
	Else If UserRight=Config.Benefit 	Then time:=Config.BenefitTime
	Else If UserRight=Config.FileAdm 	Then time:=Config.FileAdmTime
	Else If UserRight=Config.SysOp 		Then time:=Config.SysOpTime
End; {P|Init}

Procedure DefineTime;
Begin
	Init;
	Current:=Timer.tStart;
	LogInTime:=Current;
	If UserRight=Config.Guest 	 Then LogOutTime:=Current+Trunc(BigBase.RestMinutes*Timer.TixMin)
	Else If UserRight=Config.Normal  Then LogOutTime:=Current+Trunc(BigBase.RestMinutes*Timer.TixMin)
	Else If UserRight=Config.Benefit Then LogOutTime:=Current+Trunc(BigBase.RestMinutes*Timer.TixMin)
	Else If UserRight=Config.FileAdm Then LogOutTime:=Current+Trunc(BigBase.RestMinutes*Timer.TixMin)
	Else If UserRight=Config.SysOp 	 Then LogOutTime:=Current+Trunc(BigBase.RestMinutes*Timer.TixMin);
(*	WriteLn (BigBase.RestMinutes);*)
End; {P|DefineTime}

Function IsTimeOut : Boolean;
Begin
	Current:=Timer.tStart;
	IsTimeOut:=(Current>LogOutTime);
End; {F|IsTimeOut : Boolean}

Procedure GiveTime (min : Integer);
Begin
	LogOutTime:=LogOutTime+Trunc(min*TixMin);
End; {P|GiveTime}

Procedure TakeTime (min : Integer);
Begin
	LogOutTime:=LogOutTime-Trunc(min*TixMin);
End;

Function OnLine : LongInt;  (* Vraca koliko je minuta user on *)
Var temp : Real;
Begin
	Current:=Timer.tStart;
	temp:=Timer.tDiff (LogInTime,Current);
	OnLine:=Trunc( Temp / 60 );
End; {F|OnLine : Integer}

Function RestOnLine : LongInt;
Begin
	RestOnLine:=time-OnLine;
End; {P|RestOnLine}

End.

