// --------------------------------------------------------------------------------------------------------------------
// General user task. This is a support task for the mappView visualization. The following functions are implemneted
// - Create and delete user
// - Create and delete roles
// - Change password and assign roles to users
// Version 0.1
// --------------------------------------------------------------------------------------------------------------------
PROGRAM _INIT
	ArUser.PAR.FilePath := 'c:\Temp\UserDataExport.txt';			// Where to export user data
	ArUser.PAR.NumberOfUsers := SIZEOF(ArUser.DAT.Users)/SIZEOF(ArUser.DAT.Users[0]);
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
			// Create role list for current user
			idx := 0;
			brsmemset(ADR(ArUser.VIS.ListUserRole), 0, SIZEOF(ArUser.VIS.ListUserRole));			
			WHILE brsstrcmp(ADR(ArUser.DAT.Users[ArUser.VIS.ListUserIndex].Roles[idx]), ADR('')) <> 0 DO
				ArUser.VIS.ListUserRole[idx] := '{"value":"';
				brsstrcat(ADR(ArUser.VIS.ListUserRole[idx]), ADR(ArUser.DAT.Users[ArUser.VIS.ListUserIndex].Roles[idx]));
				brsstrcat(ADR(ArUser.VIS.ListUserRole[idx]), ADR('","text":"'));	
				brsstrcat(ADR(ArUser.VIS.ListUserRole[idx]), ADR(ArUser.DAT.Users[ArUser.VIS.ListUserIndex].Roles[idx]));
				brsstrcat(ADR(ArUser.VIS.ListUserRole[idx]), ADR('"}'));
				idx := idx + 1;
			END_WHILE;

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
				UserManagementState := CreateUserListGetFirstState;
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
				UserManagementState := CreateUserListGetFirstState;
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
			UserAssignRole_0(Execute := TRUE , UserName := ArUser.PAR.UserName , RoleName := ArUser.PAR.UserRole);
			
//			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF UserAssignRole_0.Done AND NOT UserAssignRole_0.Busy THEN				
				ArUser.DAT.Status := 'Role assigned';
				ArUser.CMD.RoleAssign := FALSE;
				UserManagementState := CreateUserListGetFirstState;	
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
				UserManagementState := CreateUserListGetFirstState;
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

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
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

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ImportUser_0.Done AND NOT ImportUser_0.Busy THEN
				ArUser.DAT.Status := 'Import finished';
				ArUser.CMD.Import := FALSE;
				UserManagementState := CreateUserListGetFirstState;						
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

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF SetPassword_0.Done AND NOT SetPassword_0.Busy THEN
				ArUser.DAT.Status := 'Password changed!';
				ArUser.CMD.PasswordChange := FALSE;
				UserManagementState := IdleState;
			ELSIF SetPassword_0.Error THEN
				ArUser.ERR.Number := SetPassword_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorState;
			END_IF;
			
		// --------------------------------------------------------------------------------------------------------------------
		// Create list of users and roles
		// --------------------------------------------------------------------------------------------------------------------	
		CreateUserListGetFirstState:
			// Initialize user list
			ArUserInitList_0(Execute := TRUE, ListType := USER_LISTTYPE, ElementName :='');	
			
			// --------------------------------------------------------------------------------------------------------------------	
			// Get first user name
			IF ArUserInitList_0.Done AND NOT ArUserInitList_0.Busy THEN
				ArUserGetFirst_0(Execute := TRUE , List := ArUserInitList_0.List );
				
				// --------------------------------------------------------------------------------------------------------------------	
				// Success
				IF ArUserGetFirst_0.Done THEN
					// Clear data, store user name and generate data provider for vis
					brsmemset(ADR(ArUser.DAT.Users), 0, SIZEOF(ArUser.DAT.Users));
					brsmemset(ADR(ArUser.VIS.ListUsers), 0, SIZEOF(ArUser.VIS.ListUsers));
					brsmemset(ADR(ArUser.VIS.ListRoles), 0, SIZEOF(ArUser.VIS.ListRoles));
					UserCounter := 0;																

					ArUser.DAT.Users[UserCounter].Name := ArUserGetFirst_0.ElementName;
					ArUser.VIS.ListUsers[UserCounter] := '{"value":"';
					brsstrcat(ADR(ArUser.VIS.ListUsers[UserCounter]), ADR(ArUserGetFirst_0.ElementName));					
					brsstrcat(ADR(ArUser.VIS.ListUsers[UserCounter]), ADR('","text":"'));
					brsstrcat(ADR(ArUser.VIS.ListUsers[UserCounter]), ADR(ArUserGetFirst_0.ElementName));					
					brsstrcat(ADR(ArUser.VIS.ListUsers[UserCounter]), ADR('"}'));

					// Reset function block and init counters
					ArUserGetFirst_0(Execute := FALSE);
					UserCounter := 1;																
					RoleCounter := 0;															
					UserManagementState := CreateUserListGetNextState;
					// Error
				ELSIF ArUserGetFirst_0.Error THEN
					ArUser.ERR.Number := ArUserGetFirst_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorState;					
				END_IF;
			END_IF;
			
		CreateUserListGetNextState:
			// Make sure we have space left
			IF UserCounter < ArUser.PAR.NumberOfUsers THEN
				// Get next user
				ArUserGetNext_0(Execute := TRUE , List := ArUserInitList_0.List);
				
				// --------------------------------------------------------------------------------------------------------------------	
				// Success
				IF ArUserGetNext_0.Done THEN
					// Store user name and generate data provider for vis
					ArUser.DAT.Users[UserCounter].Name := ArUserGetNext_0.ElementName;
					ArUser.VIS.ListUsers[UserCounter] := '{"value":"';
					brsstrcat(ADR(ArUser.VIS.ListUsers[UserCounter]), ADR(ArUserGetNext_0.ElementName));
					brsstrcat(ADR(ArUser.VIS.ListUsers[UserCounter]), ADR('","text":"'));	
					brsstrcat(ADR(ArUser.VIS.ListUsers[UserCounter]), ADR(ArUserGetNext_0.ElementName));
					brsstrcat(ADR(ArUser.VIS.ListUsers[UserCounter]), ADR('"}'));
					// Reset function block and get next name
					ArUserGetNext_0(Execute := FALSE , List := ArUserInitList_0.List);
					UserCounter := UserCounter + 1;
				// Error
				ELSIF ArUserGetNext_0.Error AND NOT (ArUserGetNext_0.ErrorID = END_OF_LIST) THEN
					ArUser.ERR.Number := ArUserGetNext_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorState;		
				// List is complete
				ELSIF ArUserGetNext_0.ErrorID = END_OF_LIST THEN
					// Reset function blocks and counters
					ArUserGetNext_0(Execute := FALSE);
					ArUserGetFirst_0(Execute := FALSE);
					ArUserInitList_0(Execute := FALSE);
					UserCounter := 0;																
					RoleCounter := 0;																
					UserManagementState := RoleListInitListState;
				END_IF;			
//			ELSE
//				ArUser.ERR.Number := ArUserGetNext_0.ErrorID;
//				ArUser.ERR.State := UserManagementState;
//				UserManagementState := ErrorState;					
			END_IF;	
			
		// --------------------------------------------------------------------------------------------------------------------
		// Create table of roles assigned to the table of users 
		// --------------------------------------------------------------------------------------------------------------------			
		RoleListInitListState:			
			IF UserCounter < ArUser.PAR.NumberOfUsers XOR (ArUserGetNext_0.ErrorID = END_OF_LIST) THEN				
				ArUserInitList_0(Execute := TRUE, ListType := USERROLE_LISTTYPE , ElementName := ArUser.DAT.Users[UserCounter].Name);				

				// --------------------------------------------------------------------------------------------------------------------	
				// Success
				IF ArUserInitList_0.Done  AND NOT ArUserInitList_0.Busy THEN
					ArUserGetFirst_0(Execute := TRUE , List := ArUserInitList_0.List);
					ArUser.DAT.Users[UserCounter].Roles[0] := ArUserGetFirst_0.ElementName;
					ArUserGetFirst_0(Execute := FALSE , List := ArUserInitList_0.List);									
					RoleCounter := 1;
					UserManagementState:= RoleListGetNextState;							
				// Error
				ELSIF ArUserInitList_0.Error THEN						
					IF ArUserInitList_0.ErrorID = ELEMENT_DOES_NOT_EXIST THEN
						ArUserInitList_0(Execute := FALSE, ListType :=USERROLE_LISTTYPE , ElementName :=ArUser.DAT.Users[UserCounter].Name );
						ArUserGetFirst_0(Execute := FALSE , List := ArUserInitList_0.List);
						UserCounter := 1;
						RoleCounter := 0;	
						UserManagementState := CreateRoleListGetFirstState;	 
					ELSE
						ArUser.ERR.Number := ArUserInitList_0.ErrorID;
						ArUser.ERR.State := UserManagementState;
						UserManagementState := ErrorState;
					END_IF;				
				END_IF;
			ELSE		
			
//				UserManagementState := CreateRoleListGetFirstState;		
			END_IF;		
			
		RoleListGetNextState:						
			ArUserGetNext_0(Execute := TRUE, List := ArUserInitList_0.List);
			
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserGetNext_0.Done THEN				
				ArUser.DAT.Users[UserCounter].Roles[RoleCounter] := ArUserGetNext_0.ElementName;
				ArUserGetNext_0(Execute := FALSE, List := ArUserInitList_0.List);
//				UserCounter := UserCounter + 1;
				RoleCounter := RoleCounter + 1;
			// List is complete
			ELSIF ArUserGetNext_0.ErrorID = END_OF_LIST THEN					
				UserCounter := UserCounter + 1;
				ArUserGetNext_0(Execute := FALSE, List := ArUserInitList_0.List);				
				ArUserInitList_0(Execute := FALSE, ListType :=USERROLE_LISTTYPE , ElementName :=ArUser.DAT.Users[UserCounter].Name );
				UserManagementState := RoleListInitListState;	
			// Error				
			ELSIF ArUserGetNext_0.Error THEN				
				ArUser.ERR.Number := ArUserGetNext_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorState;					 
			END_IF;
				
		// --------------------------------------------------------------------------------------------------------------------
		// Create table of roles
		// --------------------------------------------------------------------------------------------------------------------	
		CreateRoleListGetFirstState:						
			ArUserInitList_0(Execute := TRUE, ListType := ROLE_LISTTYPE , ElementName :='' );	 

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserInitList_0.Done AND NOT ArUserInitList_0.Busy THEN
				ArUserGetFirst_0(Execute := TRUE , List := ArUserInitList_0.List );						

				// --------------------------------------------------------------------------------------------------------------------	
				// Success
				IF ArUserGetFirst_0.Done THEN
					// Store role names and generate data provider for vis
					ArUser.DAT.Roles[RoleCounter] := ArUserGetFirst_0.ElementName;
					ArUser.VIS.ListRoles[RoleCounter] := '{"value":"';
					brsstrcat(ADR(ArUser.VIS.ListRoles[RoleCounter]), ADR(ArUserGetFirst_0.ElementName));					
					brsstrcat(ADR(ArUser.VIS.ListRoles[RoleCounter]), ADR('","text":"'));
					brsstrcat(ADR(ArUser.VIS.ListRoles[RoleCounter]), ADR(ArUserGetFirst_0.ElementName));					
					brsstrcat(ADR(ArUser.VIS.ListRoles[RoleCounter]), ADR('"}'));
					// Reset function block and init counters
					ArUserGetFirst_0(Execute := FALSE);
					RoleCounter := 1;
					UserManagementState := CreateRoleListGetNextState;
				// Error				
				ELSIF ArUserGetFirst_0.Error THEN
					ArUser.ERR.Number := ArUserGetFirst_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorState;					
				END_IF;
			// Error				
			ELSIF ArUserInitList_0.Error THEN
				ArUser.ERR.Number := ArUserInitList_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorState;					
			END_IF;
			
		CreateRoleListGetNextState:						
			IF UserCounter < ArUser.PAR.NumberOfUsers THEN										
				ArUserGetNext_0(Execute := TRUE , List := ArUserInitList_0.List);

				// --------------------------------------------------------------------------------------------------------------------	
				// Success
				IF ArUserGetNext_0.Done THEN
					// Store user name and generate data provider for vis
					ArUser.DAT.Roles[RoleCounter] := ArUserGetNext_0.ElementName;
					ArUser.VIS.ListRoles[RoleCounter] := '{"value":"';
					brsstrcat(ADR(ArUser.VIS.ListRoles[RoleCounter]), ADR(ArUserGetNext_0.ElementName));
					brsstrcat(ADR(ArUser.VIS.ListRoles[RoleCounter]), ADR('","text":"'));	
					brsstrcat(ADR(ArUser.VIS.ListRoles[RoleCounter]), ADR(ArUserGetNext_0.ElementName));
					brsstrcat(ADR(ArUser.VIS.ListRoles[RoleCounter]), ADR('"}'));
					// Reset function block and get next name
					ArUserGetNext_0(Execute := FALSE);
					RoleCounter := RoleCounter + 1;
				// Error				
				ELSIF ArUserGetNext_0.Error AND NOT (ArUserGetNext_0.ErrorID = END_OF_LIST) THEN
					ArUser.ERR.Number := ArUserGetNext_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorState;		
				// End of list reached				
				ELSIF ArUserGetNext_0.ErrorID = END_OF_LIST THEN
					ArUserGetNext_0(Execute := FALSE);
					ArUserGetFirst_0(Execute := FALSE);
					ArUserInitList_0(Execute := FALSE);
					RoleCounter := 0;
					ArUser.CMD.ListRefresh := FALSE;								
					UserManagementState := IdleState;
				END_IF;			
			ELSE
//				UserManagementState := IdleState;					
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
				
				UserCounter := 1;	
				RoleCounter := 0;	
			
				brsmemset(ADR(ArUser.ERR), 0, SIZEOF(ArUser.ERR));
				ArUser.CMD.ErrorReset := FALSE;
				UserManagementState := IdleState;
			END_IF;	
			brsmemset(ADR(ArUser.CMD), 0, SIZEOF(ArUser.CMD));
	END_CASE;
END_PROGRAM