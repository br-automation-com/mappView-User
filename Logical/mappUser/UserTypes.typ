
TYPE
	ClientInfoType : 	STRUCT 
		userId : WSTRING[80];
		isValid : BOOL;
		ipAddress : WSTRING[15];
		languageId : WSTRING[2];
		screenResolution : WSTRING[32];
		slotId : SINT;
	END_STRUCT;
	userManagementEnum : 
		(
		IdleUser, (*Wait state*)
		ExportList,
		ImportList,
		ErrorUser
		);
	userMAIN : 	STRUCT 
		CMD : userCMD;
		PAR : userPAR;
		ERR : userERR;
		Status : STRING[200];
	END_STRUCT;
	userCMD : 	STRUCT 
		Import : BOOL;
		Export : BOOL;
		ErrorReset : BOOL;
	END_STRUCT;
	userPAR : 	STRUCT 
		FilePath : STRING[100] := 'C:/Temp/UserDataExport.txt';
	END_STRUCT;
	userERR : 	STRUCT 
		No : DINT;
		State : userManagementEnum;
	END_STRUCT;
END_TYPE
