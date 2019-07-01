
TYPE
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
		RoleCreate : BOOL;
		RoleDelete : BOOL;
		RoleAssign : BOOL;
		Import : BOOL;
		Export : BOOL;
		ListRefresh : BOOL;
		ErrorReset : BOOL;
	END_STRUCT;
	typUSER_PAR : 	STRUCT 
		FilePath : STRING[80];
		UserName : STRING[80];
		UserRole : STRING[80];
		Password : STRING[80];
		PasswordRepeat : STRING[80];
	END_STRUCT;
	typUSER_DAT : 	STRUCT 
		Users : ARRAY[0..49]OF typUSER_DETAILS;
		Roles : ARRAY[0..19]OF STRING[80];
		Status : STRING[80];
	END_STRUCT;
	typUSER_VIS : 	STRUCT 
		New_Member : USINT;
	END_STRUCT;
	typUSER_ERR : 	STRUCT 
		Number : DINT;
		State : UserManagementEnum;
	END_STRUCT;
	typUSER_DETAILS : 	STRUCT 
		Roles : ARRAY[0..9]OF STRING[80];
		Name : STRING[80];
	END_STRUCT;
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
		RoleListMainState,
		RoleListDeleteListState,
		RoleListInitListState,
		ErrorState,
		CreateRoleListGetFirstState,
		CreateRoleListGetNextState,
		RoleListGetNextState
		);
END_TYPE
