
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
		VIS : ARRAY[0..MAX_CLIENTS]OF userVIS;
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
		UserName : STRING[MAX_ITEM_LENGTH];
		UserNameNew : STRING[MAX_ITEM_LENGTH];
		UserRole : STRING[MAX_ITEM_LENGTH];
		Password : STRING[MAX_ITEM_LENGTH];
		PasswordRepeat : STRING[MAX_ITEM_LENGTH];
		VisuSlotID : USINT;
	END_STRUCT;
	userDAT : 	STRUCT 
		Users : ARRAY[0..MAX_USER_NAMES]OF userDETAILS;
		Roles : ARRAY[0..MAX_USER_ROLES]OF STRING[MAX_ITEM_LENGTH];
		Status : STRING[100];
		UserActive : ARRAY[0..MAX_CLIENTS]OF STRING[MAX_ITEM_LENGTH];
	END_STRUCT;
	userVIS : 	STRUCT 
		ListUsers : ARRAY[0..MAX_USER_NAMES]OF STRING[MAX_ITEM_LENGTH];
		ListUserIndex : UINT;
		ListUserValue : STRING[MAX_ITEM_LENGTH];
		ListUserRole : ARRAY[0..MAX_USER_ROLES]OF STRING[MAX_ITEM_LENGTH];
		ListUserRoleIndex : UINT;
		ListRoles : ARRAY[0..MAX_USER_ROLES]OF STRING[MAX_ITEM_LENGTH];
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
		Roles : ARRAY[0..MAX_USER_ROLES]OF STRING[MAX_ITEM_LENGTH];
		Name : STRING[MAX_ITEM_LENGTH];
	END_STRUCT;
END_TYPE
