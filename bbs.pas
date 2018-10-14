{$F+,O+,X+,M 16384,0,3072}

Uses
	Overlay,
	Misc,
	MulAware;

{$O Misc     }
{$O	AutoExec }
{$O BBegin   }
{$O BBSBase  }
{$O BigBase  }
{$O BEditor  }
{$O BFiles   }
{$O Config   }
{$O Door     }
{$O	Mail     }
{$O Help		 }
{$O Red      }
{$O	SysOp    }

{$O DOS}

Procedure ShowMultitasker;
Begin
	Case MultiTasker of
		None         : Write('No MultiTasker');
		DESQview     : Write('DESQview v', Hi(MulVersion), '.', Lo(MulVersion));
		WinEnh       : Write('Windows v3.', Lo(MulVersion), ' in Enhanced Mode');
		OS2          : Write('OS/2 v', Hi(MulVersion), '.', Lo(MulVersion));
		DoubleDOS    : Write('DoubleDOS');
		Win386       : Write('Windows 386 v2.xx');
		TaskSwitcher : Write('DOS 5.0 Task Switcher or Compatible');
		WinStandard  : Write('Windows 2.xx or 3.x in Real or Standard Mode');
	end;
	WriteLn;
End;


Begin
	ShowMultiTasker;

	Overlay.OvrInit ('BBS.OVR');
	If Overlay.OvrResult<>0 Then Begin
		WriteLn ('Overlay error: ',Overlay.OvrResult);
		Halt(1);
	End;

	Misc.Redirect;
	Repeat
		Misc.StartSession; 
		Misc.TakeCommands;  
	Until FALSE;
End.
