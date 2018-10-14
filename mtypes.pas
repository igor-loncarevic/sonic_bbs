Unit	MTYPES;

INTERFACE

Var
	InitDef,
	HangDef  : String;
	ComPort,
	ComPars	 : Byte;

Const
			CR      = #13+#10;

			COM1    = 0;       { Communication ports }
      COM2    = 1;

      C110    = 0;       { Speed in BPS of COMs }
      C150    = 32;
      C300    = 64;
      C600    = 96;
      C1200   = 128;
      C2400   = 160;
      C4800   = 192;
      C9600   = 224;

      CNON    = 0;       { Parity }
      CODD    = 8;
      CEVEN   = 24;

      CSTOP1  = 0;       { Stop bits }
      CSTOP2  = 4;

      CDATA7  = 2;       { Word length }
      CDATA8  = 3;

      EMPTY   = -1;      { Empty sign }

      OFF     = 0;       { Sign when DTR is off }
      ON      = 1;       { Sign when DTR is on }

      PAUSE   = '~';     { Pause sign }
      HALFSEC = 500;     { Pause length - HALF Second }

      lnTOUT  = 128;     { Time out }
      lnTSRE  = 64;      { Trans shift register empty }
      lnTHRE  = 32;      { Trans hold register empty }
      lnBREAK = 16;      { Break detected }
      lnFRAME = 8;       { Framing error }
      lnPRTYE = 4;       { Parity error }
      lnOVRNE = 2;       { Overrun error }
      lnDTRDY = 1;       { Data ready status }

      mdCARR  = 128;     { Recived line signal detected (CARRIER)}
      mdRING  = 64;      { Ring indicator }
      mdDSR   = 32;      { Data set ready }
      mdCTS   = 16;      { Clear to send }
      mdDRLSD = 8;       { Delta recived line signal detected }
      mdTERD  = 4;       { Trailing edge ring detector }
      mdDDSR  = 2;       { Delta data set ready }
      mdDCTS  = 1;       { Delta clear to send }

      msTOUT  = 'Time out';
      msTSRE  = 'Trans shift register empty';
      msTHRE  = 'Trans hold register empty';
      msBREAK = 'Break detected';
      msFRAME = 'Framing error';
      msPRTYE = 'Parity error';
      msOVRNE = 'Overrun error';
      msDTRDY = 'Data ready status';

      msCARR  = 'Carrier detected';
      msRIGN  = 'Ring indicator';
      msDSR   = 'Data set ready';
      msCTS   = 'Clear to send';
      msDRLSD = 'Delta recived line signal detected';
      msTERD  = 'Trailing edge ring detector';
      msDDSR  = 'Delta data set ready';
      msDCTS  = 'Delta clear to send';

      eiEXIST = 1;
      eiUNREG = 2;
      eiOK    = 0;

      miEXIST = 'Already installed';
      miUNREG = 'Unknow port';
      miOK    = 'Successful installed';

      erREMOV = 1;
      erOK    = 0;

      mrREMOV = 'Already removed or not installed';
      mrOK    = 'Successfule removed';
      errmsg  = 'Unknow error - Please contact author';

      NULL    = #0;
      BS      = #8;             { BacksSpace ( <- ) }
      FORMFEED= #12;
      ESC     = #27;

			intc_mreg = $21;
      intc_creg = $20;
      EOI       = $20;

      rcv_bufsize = 8192;
      snd_bufsize = 256;

      com1_port = $03f8;
      com2_port = $02f8;
      com1_int  = $0c;
      com2_int  = $0b;
      com1_mask = $10;
      com2_mask = $08;

IMPLEMENTATION

End.