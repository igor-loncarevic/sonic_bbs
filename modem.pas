Unit	Modem;

INTERFACE

Const
	Local : Boolean = FALSE;
	Hide	: Boolean = FALSE;


Procedure Install;
Procedure Remove;
Procedure Terminal;
Procedure Out   			(s: String);
Procedure OutLn 			(s: String);
Procedure SendStr 		(s: String);
Procedure SendStrLn 	(s: String);
Procedure WaitFor 		(s: String);
Procedure InitModem;
Procedure Answer;
Procedure HangUp;

Function TakeCommand  (mesgon:Boolean) : String;
Function Rest 				(query: String): Boolean;
Function Pressed 			: Boolean;
Function ReadStr			: String;
Function Ring 				: Boolean;
Function Connected		: Boolean;

IMPLEMENTATION

Uses
	ANSI,
	BBegin,
	BFiles,
	Config,
	Crt,
	Misc,
	MTypes,
	Net,
	Red,
	Timer;

Var
	rbuf    : Array[1..MTypes.Rcv_BufSize] of Byte;
	sbuf    : Array[1..MTypes.Snd_BufSize] of Byte;
	rbufs   : Word;
	rbufe   : Word;
	sbufs   : Word;
	sbufe   : Word;

	comm_used : Byte;
	comm_int  : Byte;
	comm_port : Word;
	comm_mask : Byte;

	installed    : Byte;
	output_busy  : Byte;
	saved_vect_o : Word;
	saved_vect_s : Word;
	day_countl   : Word;
	day_counth   : Word;
	old_countl   : Word;
	old_counth   : Word;

Procedure SetVars;
Begin
	rbufs:=0;
	rbufe:=0;
	sbufs:=0;
	sbufe:=0;

	comm_used:=0;
	comm_int:=0;
	comm_port:=0;
	comm_mask:=0;

	installed:=0;
	output_busy:=0;
	day_countl:=0;
	day_counth:=0;
	old_countl:=0;
	old_counth:=0;
End;

Procedure Comm_Interrupt(Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP: Word); Interrupt; Assembler;
ASM

{ Interrupt rutina }
                mov     ax, seg(comm_port)
                mov     ds,ax

                mov     dx,comm_port       {dx stalno drzi adresu DATA porta}
    @lloop:
                inc     dx
                inc     dx                 {IIR - identifikacija izvora int}
                in      al,dx
                dec     dx
                dec     dx
                test    al,1               {postoji neobradjen interapt?}
                jz      @int_req           {da, obradi}

                mov     al,EOI             {ne, kraj interapta}
                out     intc_creg, al

                jmp     @exit3

    @int_req:
                cmp     al,2               {znak poslat, slobodno za sledeci?}
                je      @send_empty
                cmp     al,4               {Znak kompletan ceka u baferu?}
                je      @recv_ready
                jmp     @lloop

    @recv_ready:
                in      al,dx              {data port}
                mov     bx,rbufe           {mesto u baferu za sledeci znak}
                mov     byte ptr rbuf[bx],al
                inc     rbufe
                cmp     rbufe,rcv_bufsize  {vreme za okret?}
                jb      @lloop              {ne, ima jos do kraja bafera}
                mov     rbufe,0            {da, ponovo od pocetka}
                jmp     @lloop

    @send_empty:
                mov     bx,sbufs           {pozicija poslednje poslatog znaka}
                cmp     bx,sbufe           {da li u baferu ima jos za slanje?}
                jne     @do_send            {da, posalji sledeci}

                mov     output_busy,0      {nema vise za slanje}
                jmp     @lloop
    @do_send:
                mov     al,byte ptr sbuf[bx] {uzmi sledeci znak}
                out     dx, al               {data port, pocni slanje}
                mov     output_busy,1        {slanje je u toku}

                inc     bx                   {poz. sledeceg znaka za slanje}
                cmp     bx,sbufe             {ima li ih jos?}
                jne     @more_tosend          {da, onda za sada nista...}

                sub     bx,bx                {reset send pointera na pocetak}
                mov     sbufe,bx
    @more_tosend:
                mov     sbufs,bx
                jmp     @lloop
    @exit3:

END;


Function  _Comm_Install(Port: Byte): Byte; Assembler;
ASM

{
  Instalisanje drajvera

  int comm_install( port )
  RET: 1 = vec instalisan, 2 = nevazeci port, 0 = ok

}

                cmp     installed,1        {vec instalisan?}
                jne     @do_install
                mov     ax,1
    @do_install:
                xor     ax,ax              {reset pointera}
                mov     rbufs,ax
                mov     rbufe,ax
                mov     sbufs,ax
                mov     sbufe,ax

                mov     al, port            {port ( comm_used )}
                mov     comm_used, al       {COM1 parametri}
                mov     dx,com1_port
                mov     cl,com1_int
                mov     ch,com1_mask

                cmp     al,0                {trazen COM1?}
                je      @param_ok1
                cmp     al,1                {trazen COM2?}
                je      @param_ok2
                mov     ax,2
                jmp     @exit
    @param_ok2:
                mov     dx,com2_port        {COM2 parametri}
                mov     cl,com2_int
                mov     ch,com2_mask

    @param_ok1:
                mov     comm_port,dx
                mov     comm_int,cl
                mov     comm_mask,ch

                in      al,intc_mreg       {trenutno stanje mask reg}
                push    ax
                mov     al,0ffh            {zabrani sve}
                out     intc_mreg,al

                mov     ah,35h             {uzmi int vektor}
                mov     al,comm_int
                int     21h                {DOS get vector}
                mov     saved_vect_o,bx    {sacuvaj}
                mov     saved_vect_s,es

                push    ds                 {usmeri vektor na moju rutinu}
                mov     dx,offset comm_interrupt
                mov     ah,25h
                mov     al,comm_int
                push    cs
                pop     ds
                int     21h                {DOS set vector}
                pop     ds

                mov     dx,comm_port
                add     dx,4               {MCR - modem kontrolni registar}
                mov     al,00001011b       {ukljci dtr, rts i out 2}
                out     dx,al

                pop     ax                 {staro stanje mask reg}

                mov     ah,0ffh            {dozvoli com interapt}
                xor     ah,comm_mask
                and     al,ah              {0 = dozvoljen intr}

                out     intc_mreg,al
                mov     ax,1
                mov     installed, al
                dec     ax

    @exit:
END;

Function  _Comm_Remove: Byte; Assembler;
{

 Uklanjanje drajvera

 int comm_remove( void )
 RET: 1 - vec uklonjen ili nije ni instalisan, 0=ok

}
ASM

                cmp     installed,1        {vec instalisan?}
                je      @ok_remove

                mov     ax,1
    @ok_remove:
                push    ds                 {vrati stari vektor}
                mov     ah,25h
                mov     al,comm_int
                mov     dx,saved_vect_o
                mov     ds,saved_vect_s
                int     21h                {DOS set vector}
                pop     ds

                xor     ax,ax
                mov     installed, al
    @done:

END;


Function  _Comm_Get: Integer; Assembler;
{

 Prijem znaka sa com porta

 int comm_get( void )
 RET: znak ili -1 = nema

}
ASM

                mov     ax,-1              {pretpostavimo da je bafer prazan}
                mov     bx,rbufs           {pocetak = kraj, bufer zaista prazan?}
                cmp     bx,rbufe
                jne     @ready_toget
                jmp     @exit2
    @ready_toget:
                mov     al, byte ptr rbuf[bx];{uzmi znak}
                sub     ah,ah              {da integer bude "cist"}
                inc     bx
                cmp     bx,rcv_bufsize     {vreme za okret pointera?}
                jb      @no_sturn
                sub     bx,bx
    @no_sturn:
                mov     rbufs,bx
    @exit2:

END;

Function  _Modem_Status: Byte; Assembler;
{

 Modem status

 int modem_status( void )
 RET: status

}
ASM

                mov     dx,comm_port
                add     dx,6               {MSR - modem status registar}
                in      al,dx
                xor     ah,ah

END;

Function  _Modem_DTR(State: Byte): Byte; Assembler;
{

 Set/Reset DTR

 int modem_dtr( int state )
 RET: state

}

ASM

                mov     dx,comm_port
                add     dx,4               {MCR - modem kontrol registar}
                in      al,dx
                and     al,11111110b       {reset DTR}
                mov     ah, state          {state}
                and     ah,1
                or      al,ah
                out     dx,al
                and     al,1
                xor     ah,ah

END;


Procedure _Comm_SetParam(Param: Byte); Assembler;
{

 Postavljanje parametara com porta

 int comm_setparam( param );
 RET: uvek 0

}

ASM

                push    si
                push    di
              
                mov     al,param           {param}
                xor     ah,ah
                mov     dl,comm_used
                xor     dh,dh
                int     14h                {bios comm set param}

                mov     dx,comm_port
                add     dx,6               {MSR - modem status reg}
                in      al,dx
                jmp     @IER

     @IER:      sub     dx,5               {IER - registar za dozvolu inter.}
                mov     al,00000011b       {dozvola za podatak spreman 01b}
                out     dx,al              {i transmiter prazan 10b}
                jmp     @IIR


     @IIR:      inc     dx                 {IIR - identifikacija inter.}
                in      al,dx              {ocisti postojece int}
                jmp     @DATAL

     @DATAL:    sub     dx,2               {DATA registar}
                in      al,dx              {ocisti postojece int}
                jmp     @QUIT

     @QUIT:     pop     di
                pop     si
                xor     ax,ax

END;

Procedure _Comm_Put(B: Byte); Assembler;
{

 Slanje znaka na com port

 int comm_put( int c )
 RET: uvek c

}

ASM

                mov     al,b
                cmp     output_busy,1      {proces slanja iz bafera u toku?}
                je      @store_tobuf        {da, samo ostavi znak u bafer}

                mov     dx,comm_port       {pokreni interrupt za slanje}
                out     dx, al             {saljuci prvi znak}
                mov     output_busy,1      {proces slanja u toku}
                jmp     @exit3
    @store_tobuf:
                mov     bx,sbufe            {poz. poslednjeg znaka}
                cmp     bx,snd_bufsize      {ima li mesta za jos jedan?}
                jae     @store_tobuf         {ne! sacekaj da int. zavrsi slanje}

                mov     byte ptr sbuf[bx],al{stavi znak u bafer}
                inc     sbufe               {pozicija za sledeci}

    @exit3:

END;

Function Connected: Boolean; 
Begin
	 Connected:=((_Modem_Status and mdCARR)<>0);
End; (* Da li je connected *)

Function Ring: Boolean;
Begin
	Ring:=((_Modem_Status And MTypes.mdRING)<>0);
End; {F|Ring : Boolean}

Procedure Put(B: Byte);
Begin
	If Chr(B)<>PAUSE then _Comm_Put(B)
									 else Delay(HALFSEC);
End;

Procedure SendStr(S: String);
Var
	I: Integer;
	Count: Byte;

Begin
	Count:=Ord(S[0]);
	For I:=1 to Count do
		Put(Ord(S[I]));
End;

Procedure SendStrLn (S: String);
Begin
	SendStr(s+CR);
End;

Function ReadStr: String;
Var      S  : String;
         B  : Integer;
         Out: Boolean;

Begin
     Out:=False;
     S:='';
     Repeat
           B:=_Comm_Get;
           IF (B<>-1) and (B<>13) then S:=S+Chr(B)
                                  else Out:=True;
     Until Out;
     B:=_Comm_Get;      { Get and #10 out of buffer }
		 ReadStr:=S;
End;

Procedure WaitFor (s: String);
Var
	Line: String;
	Ch: Char;
	I: Integer;
	Out: Boolean;
Begin
	Out:=Boolean(FALSE);
	Line:='';
	Repeat
		I:=_Comm_Get;
		Ch:=Chr(i);
		If Not((Ch=#13) Or (Ch=#10) Or (Ch=#13#10)) Then
			Line:=Line+Ch;
		If (Ord(Line[0])>1) And (Pos(s,Line)>0) Then Out:=TRUE;
	Until Out; 
End;


Procedure Install;  
Var
	Status: Byte;
Begin
	Status:=_Comm_Install(MTypes.ComPort);
	If Status<>0 then	Begin
		If Status=eiEXIST then Modem.OutLn (miEXIST);
		If Status=eiUNREG then Modem.OutLn (miUNREG);
	End;

	_Comm_SetParam(ComPars);

	Status:=_Modem_DTR(OFF);
	Delay(HALFSEC);
	Status:=_Modem_DTR(ON);
	SendStr(INITDEF);
	Delay(HALFSEC*2);
End; (* Vrsi Inicijalizaciju portova *)


Procedure Remove;  (* Uklanja Com interupt *)
Var
	Status: Byte;
Begin
	Status:=_Comm_Install(MTypes.ComPort);
	If (Status<>0) And (Status=erREMOV) then Modem.OutLn (miEXIST);
End;

Procedure Out (s : String);
Begin
	If Red.Redirect Then Begin
		Red.Wr (s);
		Exit;
	End;
	
	If Not(Local) Then SendStr(s);
	Write(s);
End; {P|OutPut}


Procedure OutLn (s : String);
Begin
	If Red.Redirect Then Begin
		Red.Wr (s+CR);
		Exit;
	End;
	If Not(Local) Then SendStr(s+CR);
	WriteLn (s);
End;


Procedure Terminal;
Var
	B: Integer;
	C: Char;
	Line: String;
Begin
	Line:='';
	WriteLn (#13#13#10+Stat('TI')+' Terminal mode. Ring waiting. ESC for options.');
	WriteLn ('======================================================');
		
	Repeat
		Repeat
			B:=_Comm_Get;
			If B<>EMPTY then begin
				Write(Chr(B));
				If (B>31) and (B<123) Then Line:=Line+Chr(B);
				If B=13 Then Begin
					WriteLn (line);
					If Line='RING' Then Begin
						Misc.Ring:=TRUE;
						Exit;
					End;
					Line:='';
				End;
			End;
		Until B=EMPTY;

		If KeyPressed then Begin
			C:=ReadKey;
			If C=NULL then C:=Chr(Ord(ReadKey)+128)
								else Put(Ord(C));
		End;
	Until C=#27;
End;


Function TakeCommand (mesgon:Boolean) : String;
Var B: Integer;
		C: Char;
		S,
		LeftNo: String;
		Van: Boolean;
		Len : Byte;

	Procedure EscJob;
	Begin
		Len:=Ord(s[0]);
		Str(Len,LeftNo);
		If Len>0 Then Begin
			Modem.Out(#27+'['+LeftNo+'D');
			Modem.Out(ANSI.EEOLN);
			S:='';
		End;
	End;

	Procedure BackCursorJob;
	Begin
		Len:=Ord(s[0]);
		If Len>0 Then Begin
			s:=copy(s,1,Len-1);
			Modem.Out(#27+'[1D');
			Modem.Out(ANSI.EEOLN);
		End;
	End;

	Procedure BlankJob;
	Begin
		If s<>'' Then Begin
			S:=S+' ';
			If Hide Then Out(#254)
							Else Out(' ');
		End;
	End;

	Procedure HotKey (C: Char);
	Begin
		Case C Of
			#16	 : Begin
								BFiles.WriteAction2Log ('-QUIT from local keyboard'+#13#10);
								OutLn ('');
								s:='';
								If Not(Local) And Connected Then Modem.HangUp;
								Halt(0);
						 End;	
			#35	 : Begin (*ALT H*)
								BFiles.WriteAction2Log ('-HANGUP from local keyboard for '+Misc.Username+#13#10);
								OutLn ('');
								Misc.LogOut('',FALSE);
								s:='';
								Van:=TRUE;
						 End;
			#19	 : Begin (*ALT R*)
								OutLn ('');
								Misc.Relog('');
								s:='';
								Van:=TRUE;
						 End;
			#20  : Begin (*ALT T*)
								OutLn ('');
								BFiles.Tree ('');
								s:='';
								Van:=TRUE;
						 End;
			#31	 : Begin (*ALT S*)
								OutLn ('');
								Misc.UserStat (s,'');
								s:='';
								Van:=TRUE;
						End;
			#33  : Begin (*ALT F*)
								OutLn ('');
								Misc.Finger (s);
								s:='';
								Van:=TRUE;
						End;
			#131 : Begin (*ALT =*)
								 Misc.TimeHandling (Misc.ToIncrement,5);
								 s:='';
								 Van:=TRUE;
						 End;
			#130 : Begin (*ALT -*)
								 Misc.TimeHandling (Misc.ToDecrement,5);
								 s:='';
								 Van:=TRUE;
						 End;
		End;
	End;


Begin
	s:='';
	Van:=FALSE;
	If Not(Local) Then Begin
		B:=_Comm_Get;
		While (B=13) Or (B=10) do
			B:=_Comm_Get;
		If B<>-1 Then S:=S+Chr(B);
	End;

	Repeat
		If Not(Local) Then Begin
			B:=_Comm_Get;
			IF (B<>-1) and (B<>13) then
				Case Chr(B) of
					#3        : Exit; (* Ctrl C *)
					#8	 			: BackCursorJob;
					#27  			: EscJob;
					#32       : BlankJob;
				Else Begin
						S:=S+Chr(B);
						If Hide Then Out (#254)
										Else Out (Chr(B));
					End
				End
			Else If (B<>-1) And (B=13) Then Van:=TRUE;
		End; {If for local}

		If KeyPressed then Begin
			C:=ReadKey;
			Case C Of
				#3				: Exit; (* Ctrl C *)
				#32       : BlankJob;
				#27  			: EscJob;
				#8	 			: BackCursorJob;
				#13	 			: Van:=TRUE;(*Enter*)
				NULL 			: Begin (*#00*)
											C:=ReadKey;
											HotKey (C);
										End;
					Else Begin
						S:=S+C;
						If Hide Then Out (#254)
										Else Out (C);
					End;
			End;
		End;
		If MesgOn Then Net.ReadSend;
		If (Misc.ChatPrompt) And (s='') Then Net.ReadChat;
	Until Van;
	TakeCommand:=s;
End; {TakeCommand:String}


Function Rest (query: String): Boolean;
Var
	B: Integer;
	C: Char;
Begin
	Modem.Out (#13+#10+query+' ('+ANSI.BRIGHT+'Y'+ANSI.NORMAL+'es/'+ANSI.BRIGHT+'N'+ANSI.Normal+'o)? ');
	Repeat
		If Not(Local) Then Begin
			B:=_Comm_Get;
			IF (B<>-1) and (B<>13) then
				Case UpCase(Chr(B)) of
					#27,'N',#3: 	Begin
											Rest:=FALSE;
											Modem.Out (#27+'[25D'+ANSI.EEOLN+ANSI.UP1);
											Exit;
										End;
			 #32,#13,'Y': Begin
											Rest:=TRUE;
											Modem.Out (#27+'[25D'+ANSI.EEOLN+ANSI.UP1);
											Exit;
										End;
				End
			Else If B=13 Then Begin
				Rest:=TRUE;
				Exit;
			End;
		End;

		If KeyPressed then Begin
			C:=ReadKey;
			Case UpCase(C) Of
				#27,'N',#3: Begin (*ESC*)
												Rest:=FALSE;
												Modem.Out (#27+'[25D'+ANSI.EEOLN+ANSI.UP1);
												Exit;
											End;
			#32,#13,'Y': Begin
												Rest:=TRUE;
												Modem.Out (#27+'[25D'+ANSI.EEOLN+ANSI.UP1);
												Exit;
									 End;
			End; (* Case *)
		End;
	Until False;
End; {Rest:Boolean}

Function Pressed : Boolean;
Var
	B	:	Integer;
	Ch: Char;
Begin
	Pressed:=FALSE;
	If Not(Local) Then Begin
		B:=_Comm_Get;
		If (B<>-1) and (B<>13) Then Begin
			Pressed:=TRUE;
			Exit;
		End;
	End;
	If KeyPressed Then Pressed:=TRUE;
	Ch:=ReadKey;
End;


Procedure InitModem;
Begin
	If Not(LOCAL) Then Begin
		MTypes.ComPort:=Config.ComPort-1;
		MTypes.ComPars:=Config.ComPars;
		MTypes.INITDEF:=Config.ModemInitStr+CR;
		MTypes.HANGDEF:=Config.ModemHangUp+CR;
		SetVars;
		Install;
		WriteLn (ReadStr);
		WaitFor ('OK');
    WriteLn ('OK');
	End;
End;

Procedure Answer;
Begin
	If Modem.Ring Then WriteLn (':) Ring line is dettected on Modem.Ring.')
								Else WriteLn (':( Ring line is not dettected on Modem.Ring.');
	Writeln ('Answering...');
		Delay (HALFSEC);
		SendStrLn ('ATA');
		Delay (HALFSEC*5);
	WriteLn ('Waiting for connection or keypressed.');
		Repeat
		Until Modem.Connected Or Keypressed;
	WriteLn ('Connection established.');

	Misc.Local:=FALSE;
	Modem.Local:=FALSE;
	Misc.Ring:=FALSE;
End;

Procedure HangUp;
Begin
	_Modem_DTR (OFF);
	Delay (HALFSEC*3);
	SendStr ('+++');
	SendStr (HANGDEF);
	_Modem_DTR(ON);
	Delay(HALFSEC*2);
End;

End.
