// --------------------------------------------------------------------------------------------------------------------
// General user task. This is a support task for the mappView visualization. The following functions are implemneted
// - Create,rename and delete user
// - Create and delete roles
// - Change password and assign roles to users
// - Export and import user data
// Version 0.5
// --------------------------------------------------------------------------------------------------------------------
PROGRAM _INIT
	ArUser.PAR.FilePath := 'c:\Temp\UserDataExport.txt';			// Where to export user data
	ArUser.CMD.ListRefresh	:= TRUE;								// Refresh user data on boot
END_PROGRAM

PROGRAM _CYCLIC
	
	// --------------------------------------------------------------------------------------------------------------------
	// Main  machine
	// --------------------------------------------------------------------------------------------------------------------
	CASE UserManagementState OF
		// --------------------------------------------------------------------------------------------------------------------
		// IdleUser 
		// --------------------------------------------------------------------------------------------------------------------
		IdleUser:
			FOR idy:=0 TO SIZEOF(ArUser.VIS)/SIZEOF(ArUser.VIS[0])-1 DO
				// --------------------------------------------------------------------------------------------------------------------
				// Create role list for current user
				idx := 0;
				brsmemset(ADR(ArUser.VIS[idy].ListUserRole), 0, SIZEOF(ArUser.VIS[idy].ListUserRole));			
				WHILE brsstrcmp(ADR(ArUser.DAT.Users[ArUser.VIS[idy].ListUserIndex].Roles[idx]), ADR('')) <> 0 DO
					ArUser.VIS[idy].ListUserRole[idx] := '{"value":"';
					brsstrcat(ADR(ArUser.VIS[idy].ListUserRole[idx]), ADR(ArUser.DAT.Users[ArUser.VIS[idy].ListUserIndex].Roles[idx]));
					brsstrcat(ADR(ArUser.VIS[idy].ListUserRole[idx]), ADR('","text":"'));	
					brsstrcat(ADR(ArUser.VIS[idy].ListUserRole[idx]), ADR(ArUser.DAT.Users[ArUser.VIS[idy].ListUserIndex].Roles[idx]));
					brsstrcat(ADR(ArUser.VIS[idy].ListUserRole[idx]), ADR('"}'));
					idx := idx + 1;
				END_WHILE;
				// Make sure we dont delete last user role
				IF(idx > 1) THEN
					ArUser.VIS[idy].RoleDeleteEnabled := TRUE;
				ELSE
					ArUser.VIS[idy].RoleDeleteEnabled := FALSE;
				END_IF
				// Make sure we dont delete last user
				IF(UserCounterTotal[idy] > 1) THEN				
					ArUser.VIS[idy].UserDeleteEnabled := TRUE;
				ELSE
					ArUser.VIS[idy].UserDeleteEnabled := FALSE;
				END_IF	 
			END_FOR;			
	
			// --------------------------------------------------------------------------------------------------------------------
			// Create new user
			IF  (ArUser.CMD.UserCreate) THEN
				// Make sure passwords match before user is created
				IF((ArUser.PAR.Password <> '' OR ArUser.PAR.PasswordRepeat <> '') AND ArUser.PAR.Password <> ArUser.PAR.PasswordRepeat) THEN
					ArUser.ERR.Number := ERR_PASSWORD_MISMATCH;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorUser;
				ELSE					
					tmpUser := ArUser.PAR.UserName;
					ArUserCreate_0(Execute := FALSE);
					UserManagementState := CreateUser;
				END_IF
			// Assign role to user
			ELSIF (ArUser.CMD.RoleAssign) THEN
				tmpUser := ArUser.PAR.UserName;
				ArUserAssignRole_0(Execute := FALSE);
				ArUser.PAR.UserRole := ArUser.DAT.Roles[ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoleIndex];
				UserManagementState := AssignRole;
			// Remove role from user
			ELSIF (ArUser.CMD.RoleRemove) THEN	
				ArUserReleaseRole_0(Execute := FALSE);
				ArUser.PAR.UserRole := ArUser.DAT.Users[ArUser.VIS[ArUser.PAR.VisuSlotID].ListUserIndex].Roles[ArUser.VIS[ArUser.PAR.VisuSlotID].ListUserRoleIndex];
				UserManagementState := ReleaseRole;
			// Delete user
			ELSIF (ArUser.CMD.UserDelete) THEN
				// Make sure we dont delete user that is logged in
				IF(brsstrcmp(ADR(ArUser.DAT.UserActive[ArUser.PAR.VisuSlotID]), ADR(ArUser.PAR.UserName)) = 0) THEN
					ArUser.ERR.Number := ERR_DELETE_LAST_USER;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorUser;
				ELSE
					ArUserDelete_0(Execute := FALSE);
					UserManagementState := DeleteUser;
				END_IF
			// Rename user
			ELSIF (ArUser.CMD.UserRename) THEN
				// Make sure we dont delete user that is logged in
				IF(brsstrcmp(ADR(ArUser.DAT.UserActive[ArUser.PAR.VisuSlotID]), ADR(ArUser.PAR.UserName)) = 0) THEN
					ArUser.ERR.Number := ERR_RENAME_LAST_USER;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorUser;
				ELSE
					ArUserGetProperty_0(Execute := FALSE);	
					ArUserSetProperty_0(Execute := FALSE);	
					ArUserAssignRole_0(Execute := FALSE);
					ArUserDelete_0(Execute := FALSE);
					UserManagementState := RenameUser;
				END_IF
			// Export user data
			ELSIF (ArUser.CMD.Export) THEN
				ArUserExport_0(Execute := FALSE);
				UserManagementState := ExportList;
			// Import user data
			ELSIF (ArUser.CMD.Import) THEN
				ArUserImport_0(Execute := FALSE);
				UserManagementState := ImportList;
			// Change user password
			ELSIF (ArUser.CMD.PasswordChange) THEN
				ArUserSetPassword_0(Execute := FALSE);	
				UserManagementState := ComparePassword;				
			// Refresh user list
			ELSIF (ArUser.CMD.ListRefresh) THEN
				tmpUser := '';
				UserManagementState := CreateUserListGetFirst;
			END_IF;
			
			// --------------------------------------------------------------------------------------------------------------------
			// Reset fields on new command
			FOR idx:=0 TO SIZEOF(ArUser.CMD) DO
				IF brsmemcmp(ADR(ArUser.CMD) + idx, ADR(ONE), 1) = 0 THEN
					ArUser.DAT.Status := '';
 				END_IF
			END_FOR
			ArUser.CMD.ErrorReset := FALSE;
						
		// --------------------------------------------------------------------------------------------------------------------
		// Create new user
		// --------------------------------------------------------------------------------------------------------------------	
		CreateUser:
			ArUserCreate_0(Execute := TRUE , UserName := tmpUser);		

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserCreate_0.Done AND NOT ArUserCreate_0.Busy THEN
				// Create new user 
				IF(ArUser.CMD.UserCreate) THEN
					ArUser.DAT.Status := 'User ';				
					brsstrcat(ADR(ArUser.DAT.Status), ADR(ArUser.PAR.UserName));
					brsstrcat(ADR(ArUser.DAT.Status), ADR(' created'));					
					// Set password when it exists
					IF ArUser.PAR.Password <> '' THEN
						UserManagementState := ComparePassword;
					ELSE
						ArUser.PAR.UserName := '';
						UserManagementState := CreateUserListGetFirst;
					END_IF;
				// Rename existing user
				ELSE
					PropertyName := 'UserID';
					UserManagementState := PropertyRead;				
				END_IF
			// Error
			ELSIF ArUserCreate_0.Error THEN
				ArUser.ERR.Number := ArUserCreate_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;	
			END_IF;
			
		// --------------------------------------------------------------------------------------------------------------------
		// Assign user role
		// --------------------------------------------------------------------------------------------------------------------					
		AssignRole:	
			ArUserAssignRole_0(Execute := TRUE , UserName := tmpUser , RoleName := ArUser.PAR.UserRole);
			
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUser.CMD.RoleAssign AND ArUserAssignRole_0.Done AND NOT ArUserAssignRole_0.Busy THEN
				ArUser.DAT.Status := 'Role >';
				brsstrcat(ADR(ArUser.DAT.Status), ADR(ArUser.PAR.UserRole));
				brsstrcat(ADR(ArUser.DAT.Status), ADR('< assigned to user '));
				brsstrcat(ADR(ArUser.DAT.Status), ADR(ArUser.PAR.UserName));
				ArUser.PAR.UserName := '';
				UserManagementState := CreateUserListGetFirst;
			ELSIF ArUser.CMD.UserRename AND ((ArUserAssignRole_0.Done AND NOT ArUserAssignRole_0.Busy) OR (ArUserAssignRole_0.ErrorID = arUSER_ERR_ALREADY_EXISTS)) THEN
				idx := idx +1;
				// Assign next role if it exists
				IF ArUser.DAT.Users[tmpUserIdx].Roles[idx] <> '' AND idx < MaxUserRoles THEN
					ArUserAssignRole_0(Execute := FALSE);
					ArUser.PAR.UserRole := ArUser.DAT.Users[tmpUserIdx].Roles[idx];
				// Delete old user
				ELSE
					UserManagementState := DeleteUser;	
				END_IF
			// Error
			ELSIF ArUserAssignRole_0.Error THEN
				ArUser.ERR.Number := ArUserAssignRole_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;
			END_IF;	
					 
		// --------------------------------------------------------------------------------------------------------------------
		// Release user role
		// --------------------------------------------------------------------------------------------------------------------								
		ReleaseRole:
			ArUserReleaseRole_0(Execute := TRUE , UserName := ArUser.PAR.UserName , RoleName := ArUser.PAR.UserRole);

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserReleaseRole_0.Done AND NOT ArUserReleaseRole_0.Busy THEN	
				ArUser.DAT.Status := 'Role >';
				brsstrcat(ADR(ArUser.DAT.Status), ADR(ArUser.PAR.UserRole));
				brsstrcat(ADR(ArUser.DAT.Status), ADR('< removed from user '));
				brsstrcat(ADR(ArUser.DAT.Status), ADR(ArUser.PAR.UserName));
				tmpUser := ArUser.PAR.UserName;
				ArUser.PAR.UserName := '';
				UserManagementState := CreateUserListGetFirst;	
			// Error
			ELSIF ArUserReleaseRole_0.Error THEN
				ArUser.ERR.Number := ArUserReleaseRole_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;
			END_IF;
			
		// --------------------------------------------------------------------------------------------------------------------
		// Delete user
		// --------------------------------------------------------------------------------------------------------------------					
		DeleteUser:	
			ArUserDelete_0(Execute := TRUE , UserName := ArUser.PAR.UserName);		

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserDelete_0.Done AND NOT ArUserDelete_0.Busy THEN
				// User delete command
				IF ArUser.CMD.UserDelete THEN
					ArUser.DAT.Status := 'User >';
					brsstrcat(ADR(ArUser.DAT.Status), ADR(ArUser.PAR.UserName));
					brsstrcat(ADR(ArUser.DAT.Status), ADR('< deleted'));					
					tmpUser := '';
				// User rename command
				ELSE			
					ArUser.DAT.Status := 'User ';
					brsstrcat(ADR(ArUser.DAT.Status), ADR(ArUser.PAR.UserName));
					brsstrcat(ADR(ArUser.DAT.Status), ADR(' renamed to >'));					
					brsstrcat(ADR(ArUser.DAT.Status), ADR(ArUser.PAR.UserNameNew));
					brsstrcat(ADR(ArUser.DAT.Status), ADR('<'));					
					ArUser.PAR.UserName := '';
				END_IF
				UserManagementState := CreateUserListGetFirst;
			// Error
			ELSIF ArUserDelete_0.Error THEN
				ArUser.ERR.Number := ArUserDelete_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;			
			END_IF;
			
		// --------------------------------------------------------------------------------------------------------------------
		// Rename user
		// --------------------------------------------------------------------------------------------------------------------					
		RenameUser:
			tmpUserIdx := 0;
			// Find user name in list
			WHILE (brsstrcmp(ADR(ArUser.DAT.Users[tmpUserIdx].Name), ADR(ArUser.PAR.UserName)) <> 0) AND (tmpUserIdx < MaxUserNames) DO
				tmpUserIdx := tmpUserIdx + 1;
			END_WHILE;
			
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF(tmpUserIdx < MaxUserNames) THEN
				tmpUser := ArUser.PAR.UserNameNew;
				ArUserCreate_0(Execute := FALSE);
				UserManagementState := CreateUser;
			// Error when user was not found
			ELSE
				ArUser.ERR.Number := arUSER_ERR_DOES_NOT_EXIST;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;
			END_IF
			
		// --------------------------------------------------------------------------------------------------------------------
		// Read user property
		// --------------------------------------------------------------------------------------------------------------------					
		PropertyRead:	
			ArUserGetProperty_0(Execute := TRUE, ElementType := arUSER_USER_PROPERTIES , ElementName := ArUser.PAR.UserName , PropertyName := PropertyName );			

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserGetProperty_0.Done AND NOT ArUserGetProperty_0.Busy THEN
				ArUserSetProperty_0(Execute := FALSE);	
				UserManagementState := PropertyWrite;
			// Error
			ELSIF ArUserGetProperty_0.Error THEN
				ArUser.ERR.Number := ArUserGetProperty_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;			
			END_IF;
		// --------------------------------------------------------------------------------------------------------------------
		// Write user property
		// --------------------------------------------------------------------------------------------------------------------					
		PropertyWrite:	
			ArUserSetProperty_0(Execute := TRUE, ElementType := arUSER_USER_PROPERTIES , ElementName := ArUser.PAR.UserNameNew , PropertyName := PropertyName , PropertyValue := ArUserGetProperty_0.PropertyValue);

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserSetProperty_0.Done AND NOT ArUserSetProperty_0.Busy THEN
				// Read password after user ID
				IF PropertyName = 'UserID' THEN
					PropertyName := 'Password';
					ArUserGetProperty_0(Execute := FALSE);	
					UserManagementState := PropertyRead;
					// Assign roles after password
				ELSIF PropertyName = 'Password' THEN
					idx := 0;
					ArUser.PAR.UserRole := ArUser.DAT.Users[tmpUserIdx].Roles[idx];
					UserManagementState := AssignRole;
				END_IF
			// Error
			ELSIF ArUserSetProperty_0.Error THEN
				ArUser.ERR.Number := ArUserSetProperty_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;			
			END_IF;
			
		// --------------------------------------------------------------------------------------------------------------------
		// Export user list to file
		// --------------------------------------------------------------------------------------------------------------------					
		ExportList:
			ArUserExport_0(Execute := TRUE , FilePath := ArUser.PAR.FilePath);		

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserExport_0.Done AND NOT ArUserExport_0.Busy THEN
				ArUser.DAT.Status := 'Export finished';
				ArUser.CMD.Export := FALSE;
				ArUser.VIS[ArUser.PAR.VisuSlotID].ShowMessageBoxOK := TRUE;
				UserManagementState := IdleUser;						
			// Error
			ELSIF ArUserExport_0.Error THEN
				ArUser.ERR.Number := ArUserExport_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;
			END_IF;

		// --------------------------------------------------------------------------------------------------------------------
		// Import user list from file
		// --------------------------------------------------------------------------------------------------------------------					
		ImportList:
			ArUserImport_0(Execute := TRUE , FilePath := ArUser.PAR.FilePath);		

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserImport_0.Done AND NOT ArUserImport_0.Busy THEN
				ArUser.DAT.Status := 'Import finished';
				ArUser.CMD.Import := FALSE;
				ArUser.VIS[ArUser.PAR.VisuSlotID].ShowMessageBoxOK := TRUE;
				UserManagementState := CreateUserListGetFirst;						
			// Error
			ELSIF ArUserImport_0.Error THEN
				ArUser.ERR.Number := ArUserImport_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;
			END_IF;

		// --------------------------------------------------------------------------------------------------------------------
		// Change password, make sure both passwords are correct
		// --------------------------------------------------------------------------------------------------------------------					
		ComparePassword:
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF brsstrcmp(ADR(ArUser.PAR.Password), ADR(ArUser.PAR.PasswordRepeat)) = 0 THEN				
				UserManagementState := ChangePassword;				
			// Error
			ELSE				
				ArUser.ERR.Number := ERR_PASSWORD_MISMATCH;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;
			END_IF;
			
		// --------------------------------------------------------------------------------------------------------------------
		// Change password, execute password change
		// --------------------------------------------------------------------------------------------------------------------					
		ChangePassword:		
			ArUserSetPassword_0(Execute := TRUE , UserName := ArUser.PAR.UserName , Password := ArUser.PAR.Password );			

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserSetPassword_0.Done AND NOT ArUserSetPassword_0.Busy THEN
				IF ArUser.CMD.PasswordChange THEN
					ArUser.DAT.Status := 'Password for user >';
					brsstrcat(ADR(ArUser.DAT.Status), ADR(ArUser.PAR.UserName));
					brsstrcat(ADR(ArUser.DAT.Status), ADR('< changed'));					
					ArUser.CMD.PasswordChange := FALSE;
					ArUser.VIS[ArUser.PAR.VisuSlotID].ShowMessageBoxOK := TRUE;
					UserManagementState := IdleUser;
				ELSE
					UserManagementState := CreateUserListGetFirst;					
				END_IF;
			// Error
			ELSIF ArUserSetPassword_0.Error THEN
				ArUser.ERR.Number := ArUserSetPassword_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;
			END_IF;
						
			// --------------------------------------------------------------------------------------------------------------------
			// Create list of users and roles
			// --------------------------------------------------------------------------------------------------------------------	
		CreateUserListGetFirst:
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
					brsmemset(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers), 0, SIZEOF(ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers));
					brsmemset(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles), 0, SIZEOF(ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles));
					UserCounter := 0;																

					ArUser.DAT.Users[UserCounter].Name := ArUserGetFirst_0.ElementName;
					ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers[UserCounter] := '{"value":"';
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers[UserCounter]), ADR(ArUserGetFirst_0.ElementName));					
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers[UserCounter]), ADR('","text":"'));
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers[UserCounter]), ADR(ArUserGetFirst_0.ElementName));					
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers[UserCounter]), ADR('"}'));

					// Reset function block and init counters
					ArUserGetFirst_0(Execute := FALSE);
					UserCounter := 1;																
					RoleCounter := 0;															
					UserManagementState := CreateUserListGetNext;
				// Error
				ELSIF ArUserGetFirst_0.Error THEN
					ArUser.ERR.Number := ArUserGetFirst_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorUser;					
				END_IF;
			END_IF;
			
		CreateUserListGetNext:
			// Make sure we have space left
			IF UserCounter < SIZEOF(ArUser.DAT.Users)/SIZEOF(ArUser.DAT.Users[0]) THEN
				// Get next user
				ArUserGetNext_0(Execute := TRUE , List := ArUserInitList_0.List);
				
				// --------------------------------------------------------------------------------------------------------------------	
				// Success
				IF ArUserGetNext_0.Done THEN
					// Store user name and generate data provider for vis
					ArUser.DAT.Users[UserCounter].Name := ArUserGetNext_0.ElementName;
					ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers[UserCounter] := '{"value":"';
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers[UserCounter]), ADR(ArUserGetNext_0.ElementName));
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers[UserCounter]), ADR('","text":"'));	
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers[UserCounter]), ADR(ArUserGetNext_0.ElementName));
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers[UserCounter]), ADR('"}'));
					// Reset function block and get next name
					ArUserGetNext_0(Execute := FALSE);
					UserCounter := UserCounter + 1;
				// Error
				ELSIF ArUserGetNext_0.Error AND NOT (ArUserGetNext_0.ErrorID = END_OF_LIST) THEN
					ArUser.ERR.Number := ArUserGetNext_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorUser;		
				// List is complete
				ELSIF ArUserGetNext_0.ErrorID = END_OF_LIST THEN
					// Reset function blocks and counters
					ArUserGetNext_0(Execute := FALSE);
					ArUserGetFirst_0(Execute := FALSE);
					ArUserInitList_0(Execute := FALSE);
					UserCounterTotal[ArUser.PAR.VisuSlotID] := UserCounter;
					UserCounter := 0;																
					RoleCounter := 0;
					UserManagementState := RoleListInitList;
				END_IF;			
			// Error
			ELSE
				ArUser.ERR.Number := ERR_USER_LIST_TOO_SHORT;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;						
			END_IF;	
			
		// --------------------------------------------------------------------------------------------------------------------
		// Create table of roles assigned to the table of users 
		// --------------------------------------------------------------------------------------------------------------------			
		RoleListInitList:			
			IF ArUser.DAT.Users[UserCounter].Name <> '' THEN				
				ArUserInitList_0(Execute := TRUE, ListType := USERROLE_LISTTYPE , ElementName := ArUser.DAT.Users[UserCounter].Name);				

				// --------------------------------------------------------------------------------------------------------------------	
				// Success
				IF ArUserInitList_0.Done  AND NOT ArUserInitList_0.Busy THEN
					ArUserGetFirst_0(Execute := TRUE , List := ArUserInitList_0.List);
					ArUser.DAT.Users[UserCounter].Roles[0] := ArUserGetFirst_0.ElementName;
					ArUserGetFirst_0(Execute := FALSE , List := ArUserInitList_0.List);									
					RoleCounter := 1;
					UserManagementState:= RoleListGetNext;							
					// Error
				ELSIF ArUserInitList_0.Error THEN						
					ArUser.ERR.Number := ArUserInitList_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorUser;
				END_IF;
			// Finish when user roles are complete
			ELSE
				ArUserInitList_0(Execute := FALSE);
				ArUserGetFirst_0(Execute := FALSE);
				UserCounter := 1;
				RoleCounter := 0;	
				UserManagementState := CreateRoleListGetFirst;	 					
			END_IF;
			
		RoleListGetNext:						
			ArUserGetNext_0(Execute := TRUE, List := ArUserInitList_0.List);
			
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserGetNext_0.Done THEN				
				ArUser.DAT.Users[UserCounter].Roles[RoleCounter] := ArUserGetNext_0.ElementName;
				ArUserGetNext_0(Execute := FALSE, List := ArUserInitList_0.List);
				//	UserCounter := UserCounter + 1;
				RoleCounter := RoleCounter + 1;
			// List is complete
			ELSIF ArUserGetNext_0.ErrorID = END_OF_LIST THEN					
				UserCounter := UserCounter + 1;
				ArUserGetNext_0(Execute := FALSE);				
				ArUserInitList_0(Execute := FALSE);
				UserManagementState := RoleListInitList;	
			// Error				
			ELSIF ArUserGetNext_0.Error THEN				
				ArUser.ERR.Number := ArUserGetNext_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;					 
			END_IF;
				
		// --------------------------------------------------------------------------------------------------------------------
		// Create table of roles
		// --------------------------------------------------------------------------------------------------------------------	
		CreateRoleListGetFirst:						
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
					ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles[RoleCounter] := '{"value":"';
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles[RoleCounter]), ADR(ArUserGetFirst_0.ElementName));					
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles[RoleCounter]), ADR('","text":"'));
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles[RoleCounter]), ADR(ArUserGetFirst_0.ElementName));					
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles[RoleCounter]), ADR('"}'));
					// Reset function block and init counters
					ArUserGetFirst_0(Execute := FALSE);
					RoleCounter := 1;
					UserManagementState := CreateRoleListGetNext;
					// Error				
				ELSIF ArUserGetFirst_0.Error THEN
					ArUser.ERR.Number := ArUserGetFirst_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorUser;					
				END_IF;
			// Error				
			ELSIF ArUserInitList_0.Error THEN
				ArUser.ERR.Number := ArUserInitList_0.ErrorID;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;					
			END_IF;
			
		CreateRoleListGetNext:						
			IF UserCounter < SIZEOF(ArUser.DAT.Roles)/SIZEOF(ArUser.DAT.Roles[0]) THEN										
				ArUserGetNext_0(Execute := TRUE , List := ArUserInitList_0.List);

				// --------------------------------------------------------------------------------------------------------------------	
				// Success
				IF ArUserGetNext_0.Done THEN
					// Store user name and generate data provider for vis
					ArUser.DAT.Roles[RoleCounter] := ArUserGetNext_0.ElementName;
					ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles[RoleCounter] := '{"value":"';
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles[RoleCounter]), ADR(ArUserGetNext_0.ElementName));
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles[RoleCounter]), ADR('","text":"'));	
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles[RoleCounter]), ADR(ArUserGetNext_0.ElementName));
					brsstrcat(ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles[RoleCounter]), ADR('"}'));
					// Reset function block and get next name
					ArUserGetNext_0(Execute := FALSE);
					RoleCounter := RoleCounter + 1;
				// Error				
				ELSIF ArUserGetNext_0.Error AND NOT (ArUserGetNext_0.ErrorID = END_OF_LIST) THEN
					ArUser.ERR.Number := ArUserGetNext_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorUser;		
				// End of list reached				
				ELSIF ArUserGetNext_0.ErrorID = END_OF_LIST THEN
					// Show message box after succesful command except refresh
					IF(NOT ArUser.CMD.ListRefresh) THEN
						ArUser.VIS[ArUser.PAR.VisuSlotID].ShowMessageBoxOK := TRUE;
					END_IF
					// Reset function blocks
					ArUserGetNext_0(Execute := FALSE);
					ArUserGetFirst_0(Execute := FALSE);
					ArUserInitList_0(Execute := FALSE);
					RoleCounter := 0;
					// Reset command
					brsmemset(ADR(ArUser.CMD), 0, SIZEOF(ArUser.CMD));
					// Select last user if possible
					IF(tmpUser <> '') THEN
						ArUser.VIS[ArUser.PAR.VisuSlotID].ListUserValue := tmpUser;
					ELSE
						ArUser.PAR.UserName := ArUser.DAT.Users[0].Name;
					END_IF
					// Copy user data into all slots on first boot
					FOR idy:=0 TO SIZEOF(ArUser.VIS)/SIZEOF(ArUser.VIS[0])-1 DO
						IF(idy <> ArUser.PAR.VisuSlotID) THEN
							brsmemcpy(ADR(ArUser.VIS[idy].ListUsers), ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers), SIZEOF(ArUser.VIS[ArUser.PAR.VisuSlotID].ListUsers));
							brsmemcpy(ADR(ArUser.VIS[idy].ListRoles), ADR(ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles), SIZEOF(ArUser.VIS[ArUser.PAR.VisuSlotID].ListRoles));
							UserCounterTotal[idy] := UserCounterTotal[ArUser.PAR.VisuSlotID];
						END_IF
					END_FOR
					UserManagementState := IdleUser;
				END_IF;			
				// Error				
			ELSE
				ArUser.ERR.Number := ERR_ROLE_LIST_TOO_SHORT;
				ArUser.ERR.State := UserManagementState;
				UserManagementState := ErrorUser;	
			END_IF;	
		
		// --------------------------------------------------------------------------------------------------------------------
		// Error 
		// --------------------------------------------------------------------------------------------------------------------					
		ErrorUser:		
			ArUser.VIS[ArUser.PAR.VisuSlotID].ShowMessageBoxError := TRUE;
			// --------------------------------------------------------------------------------------------------------------------					
			// Generate text for most common errors
			IF(ArUser.ERR.Number = arUSER_ERR_ALREADY_EXISTS) THEN
				ArUser.DAT.Status := 'ERR: User/Role already exists or is already assigned';
			ELSIF(ArUser.ERR.Number = arUSER_ERR_PARAMETER) THEN
				ArUser.DAT.Status := 'ERR: User/Role is empty';
			ELSIF(ArUser.ERR.Number = arUSER_ERR_DOES_NOT_EXIST) THEN
				ArUser.DAT.Status := 'ERR: User/Role does not exist';
			ELSIF(ArUser.ERR.Number = ERR_PASSWORD_MISMATCH) THEN
				ArUser.DAT.Status := 'ERR: Passwords do not match';
			ELSIF(ArUser.ERR.Number = ERR_USER_LIST_TOO_SHORT) THEN
				ArUser.DAT.Status := 'ERR: User list is too short';
			ELSIF(ArUser.ERR.Number = ERR_ROLE_LIST_TOO_SHORT) THEN
				ArUser.DAT.Status := 'ERR: Role list is too short';
			ELSIF(ArUser.ERR.Number = ERR_DELETE_LAST_USER) THEN
				ArUser.DAT.Status := 'ERR: Can not delete user that is logged in';
			ELSIF(ArUser.ERR.Number = ERR_RENAME_LAST_USER) THEN
				ArUser.DAT.Status := 'ERR: Can not rename user that is logged in';
			ELSE
				ArUser.DAT.Status := 'Error executing command';
			END_IF							
			// --------------------------------------------------------------------------------------------------------------------	
			// Return to idle 
			IF ArUser.CMD.ErrorReset THEN
				ArUser.DAT.Status := '';
				
				UserCounter := 1;	
				RoleCounter := 0;	
			
				brsmemset(ADR(ArUser.ERR), 0, SIZEOF(ArUser.ERR));
				ArUser.CMD.ErrorReset := FALSE;
				ArUser.VIS[ArUser.PAR.VisuSlotID].ShowMessageBoxError := FALSE;
				UserManagementState := IdleUser;
			END_IF;	
			brsmemset(ADR(ArUser.CMD), 0, SIZEOF(ArUser.CMD));
	END_CASE;
END_PROGRAM