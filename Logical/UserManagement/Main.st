
PROGRAM _INIT
	PrintListRole;
	
END_PROGRAM

PROGRAM _CYCLIC
		
	CASE UserManagement OF
		
		InitState: 
			FilePath := 'C:\Temp\Export.txt';	//Path must be defined in .var
			ImportUser_0(Execute := TRUE , FilePath := FilePath );			
			IF ImportUser_0.Done AND NOT ImportUser_0.Busy THEN
				ImportUser_0(Execute := FALSE , FilePath := FilePath );
				UserManagement := IdleState;
				
			ELSIF ImportUser_0.Error THEN
				ImportUser_0(Execute := FALSE , FilePath := FilePath );
				ErrorID := ImportUser_0.ErrorID;
				UserManagement := ErrorState;			 
			END_IF;
			
		IdleState:				
			IF  EDGEPOS(CmdUserCreate) THEN
				UserManagement := CreateUserState;
				SystemFeedback := '';
				
				
			ELSIF EDGEPOS(CmdUserDelete) THEN
				UserManagement := DeleteUserState;
				SystemFeedback  := '';
				
				
			ELSIF EDGEPOS(CmdExport) THEN
				UserManagement := ExportListState;
				SystemFeedback  := '';	
				
				
			ELSIF EDGEPOS(CmdSetPassword) THEN
				UserManagement := ComparePasswordState;
				SystemFeedback  := '';	
				
			ELSIF EDGEPOS(CmdRefreshList) THEN	
				UserManagement := RefreshListGetFirstState;
				SystemFeedback  := '';
				
				
			ELSIF EDGEPOS(CmdAssignRole) THEN
				UserManagement := AssignRoleState;
				SystemFeedback  := '';	
				
			ELSIF EDGEPOS(CmdClearText) THEN
				UserManagement := ClearTextState;
				SystemFeedback  := '';	
								
			END_IF;
			
		CreateUserState:	
			CmdUserCreate := FALSE;
			UserCreate_0(Execute := TRUE , UserName := UserName );		
			IF UserCreate_0.Done AND NOT UserCreate_0.Busy THEN				
				UserCreate_0(Execute := FALSE , UserName := '' );
				SystemFeedback := 'Password changed';
				UserManagement := IdleState;
			ELSIF UserCreate_0.Error THEN
				UserCreate_0(Execute := FALSE , UserName := '' );
				ErrorID := UserCreate_0.ErrorID;
				UserManagement := ErrorState;	
			END_IF;
			
			
		AssignRoleState:	
			UserAssignRole_0(Execute := TRUE , UserName := AssignRoleName , RoleName := AssignRole);	
			CmdAssignRole := FALSE;
			IF UserAssignRole_0.Done AND NOT UserAssignRole_0.Busy THEN				
				UserAssignRole_0(Execute := FALSE , UserName := AssignRoleName , RoleName := AssignRole);
				SystemFeedback := 'Role assigned';
				UserManagement := IdleState;	
			ELSIF UserAssignRole_0.Error THEN
				UserAssignRole_0(Execute := FALSE , UserName := AssignRoleName , RoleName := AssignRole);
				ErrorID := UserAssignRole_0.ErrorID;
				UserManagement := ErrorState;
			END_IF;	
					
		DeleteUserState:	
			CmdUserDelete := FALSE;	
			DeleteUser_0(Execute := TRUE , UserName := UserName );		
			IF DeleteUser_0.Done AND NOT DeleteUser_0.Busy THEN				
				DeleteUser_0(Execute := FALSE, UserName := '' );
				SystemFeedback := 'User deleted';
				UserManagement := IdleState;
			ELSIF DeleteUser_0.Error THEN
				ErrorID := DeleteUser_0.ErrorID;
				DeleteUser_0(Execute := FALSE, UserName := '' );	
				UserManagement := ErrorState;				
			END_IF;	
			
		ExportListState:
			CmdExport := FALSE;
			Export_0(Execute := TRUE , FilePath := FilePath);		
			IF Export_0.Done AND NOT Export_0.Busy THEN
				Export_0(Execute := FALSE, FilePath := FilePath );
				SystemFeedback := 'Export successfully';
				UserManagement := IdleState;						
			ELSIF Export_0.Error THEN
				ErrorID := Export_0.ErrorID;
				Export_0(Execute := FALSE, FilePath := FilePath );
				UserManagement := ErrorState;
			END_IF;
			
		ComparePasswordState:
			CmdSetPassword := FALSE;
			Result := brsstrcmp(ADR(SetPassword), ADR(RepeatPassword));			
			IF Result = 0 THEN				
				UserManagement := ChangePasswordState;				
			ELSE				
				SystemFeedback := 'Passwords are not the same';
				UserManagement := IdleState;
			END_IF;
			
		ChangePasswordState:	
			
			SetPassword_0(Execute := TRUE , UserName := SetPasswordName , Password := SetPassword );			
			IF SetPassword_0.Done AND NOT SetPassword_0.Busy THEN
				SetPassword_0(Execute := FALSE , UserName := '', Password := '');	
				SystemFeedback := 'Password changed!';
				UserManagement := IdleState;
			ELSIF SetPassword_0.Error THEN
				ErrorID := SetPassword_0.ErrorID;
				SetPassword_0(Execute := FALSE , UserName := '', Password := '');					
				UserManagement := ErrorState;
			END_IF;

		RefreshListGetFirstState:						
			ArUserInitList_0(Execute := TRUE, ListType := UserPar , ElementName :='' );	 
			IF ArUserInitList_0.Done AND NOT ArUserInitList_0.Busy THEN
				CmdRefreshList := FALSE;								
				ArUserGetFirst_0(Execute := TRUE , List := ArUserInitList_0.List );						
				IF ArUserGetFirst_0.Done THEN						
					PrintListUser[0] := ArUserGetFirst_0.ElementName;
					ArUserGetFirst_0(Execute := FALSE , List := ArUserInitList_0.List );
					UserManagement := RefreshListGetNextState;
				ELSIF ArUserGetFirst_0.Error THEN
					ErrorID := ArUserGetFirst_0.ErrorID;
					ArUserGetFirst_0(Execute := FALSE , List := ArUserInitList_0.List );
					UserManagement := ErrorState;					
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
					ErrorID := ArUserGetNext_0.ErrorID;
					ArUserGetNext_0(Execute := FALSE , List := ArUserInitList_0.List);
					UserManagement := ErrorState;		
				ELSIF ArUserGetNext_0.ErrorID = -2144327714 THEN
					LoopCounter := 1;	
					i := 0;
					UserManagement := RoleListInitListState;
					ArUserGetNext_0(Execute := FALSE , List := ArUserInitList_0.List);
					ArUserGetFirst_0(Execute := FALSE , List := ArUserInitList_0.List);
					ArUserInitList_0(Execute := FALSE , ListType := UserPar, ElementName :='');								
				END_IF;			
			ELSE
				LoopCounter := 1;	
				i := 0;
				UserManagement := RoleListInitListState;					
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
						UserManagement := IdleState;	 
					ELSE
						ErrorID := ArUserInitList_1.ErrorID;
						UserManagement := ErrorState;	
					END_IF;				
				END_IF;
			ELSE				
				UserManagement := IdleState;		
			END_IF;		
		
		ErrorState:
			
			IF EDGEPOS(CmdReset) THEN				
				UserManagement := IdleState;
				CmdReset := FALSE;
			END_IF;	
		
		ClearTextState:
			CmdClearText := FALSE;
			UserName 		:='';
			SetPasswordName :='';
			SetPassword		:='';
			RepeatPassword 	:='';
			AssignRoleName	:='';
			AssignRole		:='';	
			UserManagement := IdleState; 		
	END_CASE;
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

