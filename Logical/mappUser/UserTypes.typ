
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
		IsConnected : BOOL; (*Shows if a USB stick is connected*)
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
		DestroyList,
		CreateUser,
		DeleteUser,
		RenameUser,
		ExportList,
		ImportList,
		ChangePassword,
		ComparePassword,
		CreateUserListGetNext,
		CreateUserListGetFirst,
		AssignRole,
		ReleaseRole,
		RoleListMain,
		RoleListDeleteList,
		RoleListInitList,
		CreateRoleListGetFirst,
		CreateRoleListGetNext,
		RoleListGetNext,
		PropertyRead,
		PropertyWrite,
		ErrorUser
		);
	userMAIN : 	STRUCT 
		CMD : userCMD;
		PAR : userPAR;
		DAT : userDAT;
		VIS : ARRAY[0..MAX_USER_CLIENTS]OF userVIS;
		ERR : userERR;
	END_STRUCT;
	userCMD : 	STRUCT 
		UserCreate : BOOL;
		UserDelete : BOOL;
		UserRename : BOOL;
		PasswordChange : BOOL;
		RoleAssign : BOOL;
		RoleRemove : BOOL;
		Import : BOOL;
		Export : BOOL;
		ListRefresh : BOOL;
		ErrorReset : BOOL;
	END_STRUCT;
	userPAR : 	STRUCT 
		FilePath : STRING[100];
		UserName : STRING[MAX_USER_ITEM_LEN];
		UserNameNew : STRING[MAX_USER_ITEM_LEN];
		UserRole : STRING[MAX_USER_ITEM_LEN];
		Password : STRING[MAX_USER_ITEM_LEN];
		PasswordRepeat : STRING[MAX_USER_ITEM_LEN];
		VisuSlotID : USINT;
	END_STRUCT;
	userDAT : 	STRUCT 
		Users : ARRAY[0..MAX_USER_NAMES]OF userDETAILS;
		Roles : ARRAY[0..MAX_USER_ROLES]OF STRING[MAX_USER_ITEM_LEN];
		Status : STRING[200];
		UserActive : ARRAY[0..MAX_USER_CLIENTS]OF STRING[MAX_USER_ITEM_LEN];
	END_STRUCT;
	userVIS : 	STRUCT 
		ListUsers : ARRAY[0..MAX_USER_NAMES]OF STRING[MAX_USER_ITEM_LEN];
		ListUserIndex : UINT;
		ListUserValue : STRING[MAX_USER_ITEM_LEN];
		ListUserRole : ARRAY[0..MAX_USER_ROLES]OF STRING[MAX_USER_ITEM_LEN];
		ListUserRoleIndex : UINT;
		ListRoles : ARRAY[0..MAX_USER_ROLES]OF STRING[MAX_USER_ITEM_LEN];
		ListRoleIndex : UINT;
		RoleDeleteEnabled : BOOL;
		UserDeleteEnabled : BOOL;
		ShowMessageBoxOK : BOOL;
		ShowMessageBoxError : BOOL;
	END_STRUCT;
	userERR : 	STRUCT 
		No : DINT;
		State : userManagementEnum;
		Text : STRING[100];
	END_STRUCT;
	userDETAILS : 	STRUCT 
		Roles : ARRAY[0..MAX_USER_ROLES]OF STRING[MAX_USER_ITEM_LEN];
		Name : STRING[MAX_USER_ITEM_LEN];
	END_STRUCT;
END_TYPE
