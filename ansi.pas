Unit ANSI;

INTERFACE

Const
  CLS=#27+'[2J';        (* Erase entire screen *)
  EEOLN=#27+'[K';       (* Erase from cursor end to end of line *)
  DOWN1=#27+'[1B';      (* One line down with cursor *)
  UP1=#27+'[1A';        (* One line up with cursor *)
  FORW1=#27+'[1C';      (* One line forward with cursor *)
  BACK1=#27+'[1D';      (* One line backward with cursor *)
  BRIGHT=#27+'[0;1;33m';(* Start writing in highvideo *)
  NORMAL=#27+'[0m';     (* Normal video brightnes writing *)
	BLUE=#27+'[0;34;1m';  (* Set color on blue *)
	RED=#27+'[0;31;1m';   (* Set color on red *)
	GREEN=#27+'[0;32;1m'; (* Set color on green *)


IMPLEMENTATION

End.
