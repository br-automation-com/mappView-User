
TYPE
	typUSER : 	STRUCT 
		CMD : typUSER_CMD;
		PAR : typUSER_PAR;
		DAT : typUSER_DAT;
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
	END_STRUCT;
	typUSER_PAR : 	STRUCT 
		FilePath : STRING[80];
	END_STRUCT;
	typUSER_DAT : 	STRUCT 
		Users : ARRAY[0..49]OF typUSER_DETAILS;
	END_STRUCT;
	typUSER_ERR : 	STRUCT 
		Number : UINT;
		Text : STRING[80];
		Step : USINT;
	END_STRUCT;
	typUSER_DETAILS : 	STRUCT 
		Roles : ARRAY[0..9]OF STRING[80];
		Name : STRING[80];
	END_STRUCT;
	UserManagementEnum : 
		(
		InitState,
		IdleState,
		CreateUserState,
		DeleteUserState,
		ExportListState,
		ChangePasswordState,
		RefreshListGetNextState,
		RefreshListGetFirstState,
		AssignRoleState,
		ErrorState,
		RoleListMainState,
		RoleListDeleteListState,
		RoleListInitListState,
		ComparePasswordState,
		ClearTextState
		);
	Test1 : 	STRUCT 
	END_STRUCT;
END_TYPE
