
TYPE
	ClientInfoType : 	STRUCT 
		userId : WSTRING[80];
		isValid : BOOL;
		ipAddress : WSTRING[15];
		languageId : WSTRING[2];
		screenResolution : WSTRING[32];
		slotId : SINT;
	END_STRUCT;
	rfidManagementEnum : 
		(
		IdleRFID, (*Search for reader or new tokens*)
		SetToken, (*Assign token to user*)
		SetPassword, (*Set token as user password*)
		DeleteToken, (*Delete token from user*)
		IdentifyToken, (*Identify token*)
		CreateNodeList, (* Create a list of Node-IDs from all active USB devices*)
		ReadDeviceData, (* Read out the specific data from the Node-IDs*)
		CheckDevice, (* Check RFID reader data*)
		OpenDevice, (*Open serial communication*)
		InitDevice, (*Send inital data to setup RFID reader*)
		DataWrite, (*Send data to RFID reader*)
		DataRead, (*Read data from RFID reader*)
		CloseDevice, (*Close serial connection*)
		ErrorRFID (*Error state*)
		);
	enumRFIDtype : 
		(
		RFID_5E9010_29,
		RFID_5E9030_29,
		RFID_NONE
		);
	rfidCMD : 	STRUCT 
		ReaderEnable : BOOL; (*Scan USB ports automatically*)
		TokenAssign : BOOL;
		TokenRemove : BOOL;
		ErrorReset : BOOL; (*Reset error*)
	END_STRUCT;
	rfidPAR : 	STRUCT 
		RefreshInterval : UINT; (*Intervall timer for USB device refresh*)
		DataMinLen : UDINT;
		AutoLogin : BOOL;
		UserName : STRING[40];
		Password : STRING[40];
	END_STRUCT;
	rfidDAT : 	STRUCT 
		IsConnected : BOOL; (*Shows if a USB device is connected*)
		Type : enumRFIDtype := RFID_NONE;
		Data : STRING[80];
		Cnt : UDINT;
		Status : STRING[80];
	END_STRUCT;
	rfidVIS : 	STRUCT 
		ExecuteLogin : BOOL;
		ShowMessageBoxOK : BOOL;
	END_STRUCT;
	rfidERR : 	STRUCT 
		Number : DINT;
		State : rfidManagementEnum;
	END_STRUCT;
	rfidMAIN : 	STRUCT 
		CMD : rfidCMD; (*Command structure*)
		PAR : rfidPAR; (*Parameter structure*)
		DAT : rfidDAT;
		VIS : rfidVIS; (*Error structure*)
		ERR : rfidERR; (*Error structure*)
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
		FilePath : STRING[100] := 'F:/UserDataExport.txt';
	END_STRUCT;
	userERR : 	STRUCT 
		No : DINT;
		State : userManagementEnum;
	END_STRUCT;
END_TYPE
