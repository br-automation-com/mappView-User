// --------------------------------------------------------------------------------------------------------------------
// General user task. This is a support task for the mappView visualization. The following functions are implemneted
// - Export and import user data
// Version 2.0
// --------------------------------------------------------------------------------------------------------------------
PROGRAM _INIT
END_PROGRAM

PROGRAM _CYCLIC

	FOR override:=0 TO MAX_CYCLES DO
		// --------------------------------------------------------------------------------------------------------------------
		// User managment state machine
		// --------------------------------------------------------------------------------------------------------------------
		CASE UserManagementState OF
			// --------------------------------------------------------------------------------------------------------------------
			// Wait for new command
			// --------------------------------------------------------------------------------------------------------------------
			IdleUser:
		
				// --------------------------------------------------------------------------------------------------------------------
				// Rename user
				IF (ArUser.CMD.Export) THEN
					ArUserExport_0(Execute := FALSE);
					UserManagementState := ExportList;
					// Import user data
				ELSIF (ArUser.CMD.Import) THEN
					ArUserImport_0(Execute := FALSE);
					UserManagementState := ImportList;
				END_IF;
				
				// --------------------------------------------------------------------------------------------------------------------
				// Reset fields on new command
				ArUser.CMD.ErrorReset := FALSE;

				
				// --------------------------------------------------------------------------------------------------------------------
				// Export user list to file
				// --------------------------------------------------------------------------------------------------------------------					
			ExportList:
				ArUserExport_0(Execute := TRUE, FilePath := ArUser.PAR.FilePath);		
	
				// --------------------------------------------------------------------------------------------------------------------	
				// Success
				IF ArUserExport_0.Done AND NOT ArUserExport_0.Busy THEN
					ArUser.Status := 'Export finished';
					ArUser.CMD.Export := FALSE;
					UserManagementState := IdleUser;						
					// Error
				ELSIF ArUserExport_0.Error THEN
					ArUser.ERR.No := ArUserExport_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorUser;
				END_IF;
	
				// --------------------------------------------------------------------------------------------------------------------
				// Import user list from file
				// --------------------------------------------------------------------------------------------------------------------					
			ImportList:
				ArUserImport_0(Execute := TRUE, FilePath := ArUser.PAR.FilePath);		
	
				// --------------------------------------------------------------------------------------------------------------------	
				// Success
				IF ArUserImport_0.Done AND NOT ArUserImport_0.Busy THEN
					ArUser.Status := 'Import finished';
					ArUser.CMD.Import := FALSE;
					UserManagementState := IdleUser;						
					// Error
				ELSIF ArUserImport_0.Error THEN
					ArUser.ERR.No := ArUserImport_0.ErrorID;
					ArUser.ERR.State := UserManagementState;
					UserManagementState := ErrorUser;
				END_IF;
	

				// --------------------------------------------------------------------------------------------------------------------
				// Error 
				// --------------------------------------------------------------------------------------------------------------------					
			ErrorUser:
				// --------------------------------------------------------------------------------------------------------------------					
				// Reset function blocks
				ArUserImport_0(Execute := FALSE);
				ArUserExport_0(Execute := FALSE);
				
				// --------------------------------------------------------------------------------------------------------------------					
				// Generate text for most common errors
				IF(ArUser.ERR.No = arUSER_ERR_PARAMETER) THEN
					ArUser.Status := 'ERR: path is empty';
				ELSE
					ArUser.Status := 'Error executing command';
				END_IF							
				// --------------------------------------------------------------------------------------------------------------------	
				// Return to idle state
				IF ArUser.CMD.ErrorReset THEN
				
					brsmemset(ADR(ArUser.ERR), 0, SIZEOF(ArUser.ERR));
					ArUser.CMD.ErrorReset := FALSE;
					UserManagementState := IdleUser;
				END_IF;	
				brsmemset(ADR(ArUser.CMD), 0, SIZEOF(ArUser.CMD));
				RETURN;
		END_CASE;
	END_FOR;			

END_PROGRAM
