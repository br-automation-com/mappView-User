
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
