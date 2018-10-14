Uses
	BBSBase;

Begin
	BBSBase.Base:='c:\bbs\userdat\bbsbase.dbf';

	Create_dbf;
	Make_dbf;
	Close_dbf;

	BBSBase.Add_Member ('Igor','Loncarevic','City','anubis','s','128');
End.