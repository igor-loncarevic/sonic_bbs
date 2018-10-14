Unit	Timer;

INTERFACE

Uses
	Crt,
	Dos;

Const
	TixSec  = 18.20648193;
	TixMin  = TixSec * 60.0;
	TixHour = TixMin * 60.0;
	TixDay  = TixHour * 24.0;

Type
	DIffType = String[16];

Var
	tGet : Longint Absolute $0040:$006C;

Function tStart: Longint;
Function tDIff(StartTime,EndTime: Longint) : Real;
Function tFormat(T1,T2:Longint): DIffType;
Procedure GetTime(H,M,S,S100:Word);

IMPLEMENTATION

Var
	 TimeDIff   : DIffType;

{ tStart - wait For a new tick, and return the
  tick number to the caller.  The wait allows
  us to be sure the user gets a start at the
  beginning of the second.	                     }

FUNCTION tStart: Longint;
VAR
   StartTime : Longint;
Begin
  	StartTime := tGet;
		While StartTime = tGet Do;
  	tStart := tGet
End;

{ tDIff - compute the dIfference between two
	timepoints (in seconds). }

FUNCTION tDIff(StartTime,EndTime: Longint) : Real;
Begin
	 tDIff := (EndTime-StartTime)/TixSec;
End;

PROCEDURE GetTime(H,M,S,S100:Word);
VAR
   Regs : Registers;
Begin
   Regs.AH := $2C;
   MsDos(Regs);
   H := Regs.CH;
   M := Regs.CL;
   S := Regs.DH;
   S100 := Regs.DL
End;

{ tFormat - given two times, return a pointer
	to a (static) String that is the dIfference
	in the times, Formatted HH:MM:SS }

FUNCTION tFormat(T1,T2:Longint): DIffType;

FUNCTION rMod(P1,P2: Real): Real;
Begin
   rMod := Frac(P1/P2) * P2
End;

VAR
	Temp : Real;
	 tStr : String;
	 TempStr : String[2];
	 TimeValue : ARRAY [1..4] OF Longint;
   I : Integer;
Begin
	 Temp := t2-t1;           { Time dIff. }
   {Adj midnight crossover}
	 If Temp<0 Then Temp:=Temp+TixDay;

	 TimeValue[1] := Trunc(Temp/TixHour);  					{hours}
	 Temp:=rMod(Temp,TixHour);
	 TimeValue[2] := Trunc(Temp/TixMin);	 					{minutes}
	 Temp:=rMod(Temp,TixMin);
	 TimeValue[3] := Trunc(Temp/TixSec);	 					{seconds}
	 Temp:=rMod(Temp,TixSec); 				    	
	 TimeValue[4] := Trunc(Temp*100.0/TixSec+0.5); 	{milliseconds}

	 Str(TimeValue[1]:2,tStr);
	 If tStr[1] = ' ' Then tStr[1] := '0';
	 For I:=2 To 3 Do	Begin
		Str(TimeValue[I]:2,TempStr);
		If TempStr[1]=' ' Then	TempStr[1]:='0';
		tStr := tStr + ':'+ TempStr
	 End;

	 Str(TimeValue[4]:2,TempStr);
	 If TempStr[1]=' ' Then TempStr[1]:='0';
	 tStr := tStr + '.' + TempStr;
	 tFormat := tStr
End;

End.
