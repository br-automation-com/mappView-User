
PROGRAM _INIT
	// ----------------------------------------------------------------------------
	// Set default values
	CmdUserCreate := FALSE;
	FilePath := 'C:\Temp\UserExport.txt';
	 
END_PROGRAM

PROGRAM _CYCLIC
	// ----------------------------------------------------------------------------
	// Create a new user
	IF EDGEPOS(CmdUserCreate) THEN
		UserCreate_0.Execute := TRUE;
		UserCreate_0.UserName := SetUserName;

		SetPassword_0.Execute := TRUE; 
		SetPassword_0.UserName := SetUserName;
		SetPassword_0.Password := SetUserPassword;
	END_IF;
	IF UserCreate_0.Done THEN
		UserCreate_0.Execute := FALSE;
	END_IF;
	IF SetPassword_0.Done THEN
		SetPassword_0.Execute := FALSE;
		IF(NOT SetPassword_0.Error) THEN
			visDialogOK := TRUE;
		END_IF
	END_IF;
	IF UserCreate_0.Done AND SetPassword_0.Done THEN
		CmdUserCreate := FALSE;
		IF(NOT UserCreate_0.Error) THEN
			visDialogOK := TRUE;
		END_IF
	END_IF;
	UserCreate_0();
	SetPassword_0();

	// ----------------------------------------------------------------------------
	// Delete an user
	IF CmdUserDelete THEN
		DeleteUser_0.Execute := TRUE;
		DeleteUser_0.UserName := SetUserName;
		DeleteUser_0();
		
		IF DeleteUser_0.Done THEN
			IF(NOT DeleteUser_0.Error) THEN
				visDialogOK := TRUE;
			END_IF
			DeleteUser_0.Execute := FALSE;
			CmdUserDelete := FALSE;
		END_IF;		
	END_IF
		 
	// ----------------------------------------------------------------------------
	// Change password
	IF CmdSetPassword THEN
		SetPassword_0.Execute := TRUE;
		SetPassword_0.UserName := SetUserName;
		SetPassword_0.Password := SetUserPassword;		
		SetPassword_0();
		
		IF SetPassword_0.Done THEN
			IF(NOT SetPassword_0.Error) THEN
				visDialogOK := TRUE;
			END_IF
			SetPassword_0.Execute := FALSE;	
			CmdSetPassword := FALSE;
		END_IF;				
	END_IF;
	
	// ----------------------------------------------------------------------------
	// Assign new role to user
	IF CmdAssignRole THEN
		UserAssignRole_0.Execute := TRUE;
		UserAssignRole_0.UserName := SetUserName;
		UserAssignRole_0.RoleName := SetUserRole;
		UserAssignRole_0();
		
		IF UserAssignRole_0.Done THEN
			UserAssignRole_0.Execute := FALSE;
			CmdAssignRole := FALSE;
		END_IF;	 
	END_IF;
	
	// ----------------------------------------------------------------------------
	// Export user data
	IF CmdExportUser THEN
		Export_0.Execute := TRUE;
		Export_0.FilePath := FilePath;
		Export_0();
		
		IF Export_0.Done THEN
			Export_0.Execute := FALSE;
			CmdExportUser := FALSE;
		END_IF;	 
	END_IF;
	
	// ----------------------------------------------------------------------------
	// Import user data
	IF CmdImportUser THEN
		ImportUser_0.Execute := TRUE;
		ImportUser_0.FilePath := FilePath;
		ImportUser_0();
		
		IF ImportUser_0.Done THEN
			ImportUser_0.Execute := FALSE;
			CmdImportUser := FALSE;
		END_IF;	 
	END_IF;
	
END_PROGRAM



