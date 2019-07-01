// --------------------------------------------------------------------------------------------------------------------
// General user task. This is a support task for the mappView visualization. The following functions are implemneted
// - Create and delete user
// - Create and delete roles
// - Change password and assign roles to users
// Version 0.1
// --------------------------------------------------------------------------------------------------------------------
PROGRAM _INIT
	ArUser.PAR.FilePath := 'c:\Temp\UserDataExport.txt';			// Where to export user data
	NumberOfUsers := SIZEOF(ArUser.DAT.Users)/SIZEOF(ArUser.DAT.Users[0]);
END_PROGRAM

PROGRAM _CYCLIC
		
	// --------------------------------------------------------------------------------------------------------------------
	// Main state machine
	// --------------------------------------------------------------------------------------------------------------------
	CASE UserManagementState OF
		// --------------------------------------------------------------------------------------------------------------------
		// Idle state
		// --------------------------------------------------------------------------------------------------------------------
		IdleState:
			// --------------------------------------------------------------------------------------------------------------------
			// Wait for new command
			IF  (ArUser.CMD.UserCreate) THEN
				UserCreate_0(Execute := FALSE);
				UserManagementState := CreateUserState;
			ELSIF (ArUser.CMD.RoleAssign) THEN
				UserAssignRole_0(Execute := FALSE);
				UserManagementState := AssignRoleState;
			ELSIF (ArUser.CMD.UserDelete) THEN
				DeleteUser_0(Execute := FALSE);
				UserManagementState := DeleteUserState;
			ELSIF (ArUser.CMD.Export) THEN
				ExportUser_0(Execute := FALSE);
				UserManagementState := ExportListState;
			ELSIF (ArUser.CMD.Import) THEN
				ImportUser_0(Execute := FALSE);
				UserManagementState := ImportListState;
			ELSIF (ArUser.CMD.PasswordChange) THEN
				SetPassword_0(Execute := FALSE);	
				UserManagementState := ComparePasswordState;
			ELSIF (ArUser.CMD.ListRefresh) THEN	
				UserManagementState := RefreshListGetFirstState;
			END_IF;
			
			// --------------------------------------------------------------------------------------------------------------------
			// Reset fields on new command
			IF ArUser.CMD.UserCreate OR ArUser.CMD.UserDelete OR ArUser.CMD.RoleCreate OR ArUser.CMD.RoleCreate OR ArUser.CMD.RoleDelete OR ArUser.CMD.RoleAssign OR ArUser.CMD.PasswordChange OR ArUser.CMD.ListRefresh OR ArUser.CMD.Import OR ArUser.CMD.Export OR ArUser.CMD.ErrorReset THEN
				ArUser.DAT.Status := '';
			END_IF;
			
		// --------------------------------------------------------------------------------------------------------------------
		// Create new user
		// --------------------------------------------------------------------------------------------------------------------	
		CreateUserState:	
			UserCreate_0(Execute := TRUE , UserName := ArUser.PAR.UserName);		

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF UserCreate_0.Done AND NOT UserCreate_0.Busy THEN				
				ArUser.DAT.Status := 'User created';
				ArUser.CMD.UserCreate := FALSE;
				UserManagementState := IdleState;
			// Error
			ELSIF UserCreate_0.Error THEN
				ArUser.ERR.Number := UserCreate_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorState;	
			END_IF;
			
		// --------------------------------------------------------------------------------------------------------------------
		// Assign user role
		// --------------------------------------------------------------------------------------------------------------------					
		AssignRoleState:	
			UserAssignRole_0(Execute := TRUE , UserName := AssignRoleName , RoleName := AssignRole);
			
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF UserAssignRole_0.Done AND NOT UserAssignRole_0.Busy THEN				
				ArUser.DAT.Status := 'Role assigned';
				ArUser.CMD.RoleAssign := FALSE;
				UserManagementState := IdleState;	
			// Error
			ELSIF UserAssignRole_0.Error THEN
				ArUser.ERR.Number := UserAssignRole_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorState;
			END_IF;	
					
		// --------------------------------------------------------------------------------------------------------------------
		// Delete user
		// --------------------------------------------------------------------------------------------------------------------					
		DeleteUserState:	
			DeleteUser_0(Execute := TRUE , UserName := ArUser.PAR.UserName);		

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF DeleteUser_0.Done AND NOT DeleteUser_0.Busy THEN				
				ArUser.DAT.Status := 'User deleted';
				ArUser.CMD.UserDelete := FALSE;
				UserManagementState := IdleState;
			// Error
			ELSIF DeleteUser_0.Error THEN
				ArUser.ERR.Number := DeleteUser_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorState;			
			END_IF;	
			
		// --------------------------------------------------------------------------------------------------------------------
		// Export user list to file
		// --------------------------------------------------------------------------------------------------------------------					
		ExportListState:
			ExportUser_0(Execute := TRUE , FilePath := ArUser.PAR.FilePath);		
			IF ExportUser_0.Done AND NOT ExportUser_0.Busy THEN
				ArUser.DAT.Status := 'Export finished';
				ArUser.CMD.Export := FALSE;
				UserManagementState := IdleState;						
			ELSIF ExportUser_0.Error THEN
				ArUser.ERR.Number := ExportUser_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorState;
			END_IF;

		// --------------------------------------------------------------------------------------------------------------------
		// Import user list from file
		// --------------------------------------------------------------------------------------------------------------------					
		ImportListState:
			ImportUser_0(Execute := TRUE , FilePath := ArUser.PAR.FilePath);		
			IF ImportUser_0.Done AND NOT ImportUser_0.Busy THEN
				ArUser.DAT.Status := 'Import finished';
				ArUser.CMD.Import := FALSE;
				UserManagementState := IdleState;						
			ELSIF ImportUser_0.Error THEN
				ArUser.ERR.Number := ImportUser_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorState;
			END_IF;

		// --------------------------------------------------------------------------------------------------------------------
		// Change password, make sure both passwords are correct
		// --------------------------------------------------------------------------------------------------------------------					
		ComparePasswordState:
			IF brsstrcmp(ADR(ArUser.PAR.Password), ADR(ArUser.PAR.PasswordRepeat)) = 0 THEN				
				UserManagementState := ChangePasswordState;				
			ELSE				
				ArUser.ERR.Number := ERR_PASSWORD_MISMATCH;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorState;
			END_IF;
			
		// --------------------------------------------------------------------------------------------------------------------
		// Change password, execute password change
		// --------------------------------------------------------------------------------------------------------------------					
		ChangePasswordState:		
			SetPassword_0(Execute := TRUE , UserName := ArUser.PAR.UserName , Password := ArUser.PAR.Password );			

			IF SetPassword_0.Done AND NOT SetPassword_0.Busy THEN
				ArUser.DAT.Status := 'Password changed!';
				ArUser.CMD.PasswordChange := FALSE;
				UserManagementState := IdleState;
			ELSIF SetPassword_0.Error THEN
				ArUser.ERR.Number := SetPassword_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorState;
			END_IF;

		RefreshListGetFirstState:						
			ArUserInitList_0(Execute := TRUE, ListType := UserPar , ElementName :='' );	 
			IF ArUserInitList_0.Done AND NOT ArUserInitList_0.Busy THEN
				ArUser.CMD.ListRefresh := FALSE;								
				ArUserGetFirst_0(Execute := TRUE , List := ArUserInitList_0.List );						
				IF ArUserGetFirst_0.Done THEN						
					PrintListUser[0] := ArUserGetFirst_0.ElementName;
					ArUserGetFirst_0(Execute := FALSE , List := ArUserInitList_0.List );
					UserManagementState := RefreshListGetNextState;
				ELSIF ArUserGetFirst_0.Error THEN
					ArUser.ERR.Number := ArUserGetFirst_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorState;					
				END_IF;
			END_IF;
			
		RefreshListGetNextState:						
			IF LoopCounter < NumberOfUsers THEN										
				ArUserGetNext_0(Execute := TRUE , List := ArUserInitList_0.List);
				IF ArUserGetNext_0.Done THEN
					PrintListUser[LoopCounter] := ArUserGetNext_0.ElementName;
					ArUserGetNext_0(Execute := FALSE , List := ArUserInitList_0.List);
					LoopCounter := LoopCounter + 1;
				ELSIF ArUserGetNext_0.Error AND NOT ( ArUserGetNext_0.ErrorID = -2144327714) THEN
					ArUser.ERR.Number := ArUserGetNext_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorState;		
				ELSIF ArUserGetNext_0.ErrorID = -2144327714 THEN
					LoopCounter := 1;	
					i := 0;
					UserManagementState := RoleListInitListState;
					ArUserGetNext_0(Execute := FALSE , List := ArUserInitList_0.List);
					ArUserGetFirst_0(Execute := FALSE , List := ArUserInitList_0.List);
					ArUserInitList_0(Execute := FALSE , ListType := UserPar, ElementName :='');								
				END_IF;			
			ELSE
				LoopCounter := 1;	
				i := 0;
				UserManagementState := RoleListInitListState;					
			END_IF;			

			
		RoleListInitListState:			
			IF i < NumberOfUsers XOR ( ArUserGetNext_0.ErrorID = -2144327714) THEN				
				ArUserInitList_1(Execute := TRUE, ListType := RolePar , ElementName :=PrintListUser[i] );				
				IF ArUserInitList_1.Done  AND NOT ArUserInitList_1.Busy THEN
					ArUserGetFirst_1(Execute := TRUE , List := ArUserInitList_1.List);
					PrintListRole[i,0] := ArUserGetFirst_1.ElementName; 
					i := i + 1;
					ArUserInitList_1(Execute := FALSE, ListType :=RolePar , ElementName :=PrintListUser[i] );
					ArUserGetFirst_1(Execute := FALSE , List := ArUserInitList_1.List);				
				ELSIF ArUserInitList_1.Error THEN						
					IF ArUserInitList_1.ErrorID = -1070585892 THEN
						ArUserInitList_1(Execute := FALSE, ListType :=RolePar , ElementName :=PrintListUser[i] );
						ArUserGetFirst_1(Execute := FALSE , List := ArUserInitList_1.List);
						UserManagementState := IdleState;	 
					ELSE
						ArUser.ERR.Number := ArUserInitList_1.ErrorID;
						ArUser.ERR.State := UserManagementState;
						UserManagementState := ErrorState;
					END_IF;				
				END_IF;
			ELSE				
				UserManagementState := IdleState;		
			END_IF;		
		
		// --------------------------------------------------------------------------------------------------------------------
		// Error state
		// --------------------------------------------------------------------------------------------------------------------					
		ErrorState:
			
			// --------------------------------------------------------------------------------------------------------------------					
			// Generate text for most common errors
			IF(ArUser.ERR.Number = arUSER_ERR_ALREADY_EXISTS) THEN
				ArUser.DAT.Status := 'ERR: User/Role already exists';
			ELSIF(ArUser.ERR.Number = arUSER_ERR_PARAMETER) THEN
				ArUser.DAT.Status := 'ERR: User/Role is empty';
			ELSIF(ArUser.ERR.Number = arUSER_ERR_DOES_NOT_EXIST) THEN
				ArUser.DAT.Status := 'ERR: User/Role does not exist';
			ELSIF(ArUser.ERR.Number = ERR_PASSWORD_MISMATCH) THEN
				ArUser.DAT.Status := 'ERR: Passwords do not match';
			END_IF							
			// --------------------------------------------------------------------------------------------------------------------	
			// Return to idle state
			IF ArUser.CMD.ErrorReset THEN
				ArUser.DAT.Status := '';
				brsmemset(ADR(ArUser.ERR), 0, SIZEOF(ArUser.ERR));
				ArUser.CMD.ErrorReset := FALSE;
				UserManagementState := IdleState;
			END_IF;	
			brsmemset(ADR(ArUser.CMD), 0, SIZEOF(ArUser.CMD));
	END_CASE;
END_PROGRAM