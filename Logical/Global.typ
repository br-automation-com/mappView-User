
TYPE
	UserManagementEnum : 
		(
		IdleState,
		DestroyListState,
		CreateUserState,
		DeleteUserState,
		ExportListState,
		ImportListState,
		ChangePasswordState,
		ComparePasswordState,
		CreateUserListGetNextState,
		CreateUserListGetFirstState,
		AssignRoleState,
		ReleaseRoleState,
		RoleListMainState,
		RoleListDeleteListState,
		RoleListInitListState,
		ErrorState,
		CreateRoleListGetFirstState,
		CreateRoleListGetNextState,
		RoleListGetNextState
		);
	typUSER : 	STRUCT 
		CMD : typUSER_CMD;
		PAR : typUSER_PAR;
		DAT : typUSER_DAT;
		VIS : typUSER_VIS;
		ERR : typUSER_ERR;
	END_STRUCT;
	typUSER_CMD : 	STRUCT 
		UserCreate : BOOL;
		UserDelete : BOOL;
		PasswordChange : BOOL;
		RoleAssign : BOOL;
		RoleRemove : BOOL;
		Import : BOOL;
		Export : BOOL;
		ListRefresh : BOOL;
		ErrorReset : BOOL;
	END_STRUCT;
	typUSER_PAR : 	STRUCT 
		FilePath : STRING[80];
		UserName : STRING[40];
		UserRole : STRING[40];
		Password : STRING[40];
		PasswordRepeat : STRING[40];
	END_STRUCT;
	typUSER_DAT : 	STRUCT 
		Users : ARRAY[0..MaxUserNames]OF typUSER_DETAILS;
		Roles : ARRAY[0..MaxUserRoles]OF STRING[40];
		Status : STRING[80];
	END_STRUCT;
	typUSER_VIS : 	STRUCT 
		ListUsers : ARRAY[0..MaxUserNames]OF STRING[80];
		ListUserIndex : UINT;
		ListUserRole : ARRAY[0..MaxUserRoles]OF STRING[80];
		ListUserRoleIndex : UINT;
		ListRoles : ARRAY[0..MaxUserRoles]OF STRING[80];
		ListRoleIndex : UINT;
		RoleDeleteEnabled : BOOL;
		UserDeleteEnabled : BOOL;
		ShowMessageBoxOK : BOOL;
		ShowMessageBoxError : BOOL;
	END_STRUCT;
	typUSER_ERR : 	STRUCT 
		Number : DINT;
		State : UserManagementEnum;
	END_STRUCT;
	typUSER_DETAILS : 	STRUCT 
		Roles : ARRAY[0..9]OF STRING[40];
		Name : STRING[40];
	END_STRUCT;
END_TYPE
