// --------------------------------------------------------------------------------------------------------------------
// This task allows user login with RFID tokens. The following functions are implemneted
// - Assign or remove token from user
// Version 1.0
//
// Error numbers
// 50000 Read response exceeds maximum buffer size
// 50010 RFID response is incorrect
// 50020 Read response timeout
// -----------------------------------------------------------------------------------------------------------
PROGRAM _INIT
	// -----------------------------------------------------------------------------------------------------------
	// Start auto scan, set default parameters
	RFID.CMD.AutoScan := TRUE;					// AutoScan for RFID reader and token data
	RFID.PAR.AutoLogin := TRUE;					// Auto login user when token is detected
	RFID.PAR.RefreshInterval := 50;				// Read data every 500ms
	RFID.PAR.DataMinLen := 16;					// Mimimum length of RFID data, everything shorter will be ignored	
	
	// -----------------------------------------------------------------------------------------------------------
	// Use configuration for RFID reader 5C9010.29
	brsmemcpy(ADR(CFG_ACTIVE), ADR(CFG_5C9010_29), SIZEOF(CFG_5C9010_29));		// Active configuration for RFID reader
	REQ_ACTIVE := REQ_5C9010_29;												// Active command to request token ID
	
	// -----------------------------------------------------------------------------------------------------------
	// Use mappUser sample variables when it exists
	PV_xgetadr(ADR('ArUser.PAR.UserName'), ADR(ArUserNameAdr), ADR(ArUserNameLen));
	PV_xgetadr(ADR('ArUser.PAR.Password'), ADR(ArUserPasswordAdr), ADR(ArUserPasswordLen));

END_PROGRAM

PROGRAM _CYCLIC

	CASE rfid_state OF
		// -----------------------------------------------------------------------------------------------------------
		// IdleRFID state
		// -----------------------------------------------------------------------------------------------------------
		IdleRFID:
			// --------------------------------------------------------------------------------------------------------------------	
			// Remove token from user
			IF (RFID.CMD.TokenRemove) THEN
				// Use user name from ArUser template when it exists
				IF(ArUserNameAdr <> 0 AND ArUserPasswordAdr <> 0) THEN
					brsstrcpy(ADR(RFID.PAR.UserName), ArUserNameAdr);					
					brsstrcpy(ADR(RFID.PAR.Password), ArUserNameAdr);					
				END_IF
				ArUserSetToken_0(Execute := FALSE);
				rfid_state := SetToken;
			END_IF
			// Refresh USB data every X seconds when enabled
			IF RFID.CMD.AutoScan = TRUE THEN
				// --------------------------------------------------------------------------------------------------------------------	
				// Get new RFID data
				TimerAutoScan(IN:=1, PT:=RFID.PAR.RefreshInterval);
				IF(TimerAutoScan.Q) THEN
					TimerAutoScan(IN:=0);
					node := 0;
					IF(RFID.PAR.IsConnected) THEN
						data_write := REQ_ACTIVE;
						callback := IdleRFID;
						rfid_state := DataWrite;
					ELSE
						brsmemset(ADR(usb_data), 0, SIZEOF(usb_data));
						rfid_state := CreateNodeList;
					END_IF
				END_IF
				
				// --------------------------------------------------------------------------------------------------------------------	
				// When RFID reader is connected
				IF RFID.PAR.IsConnected = TRUE THEN
					// --------------------------------------------------------------------------------------------------------------------	
					// Assign token to user
					IF (RFID.CMD.TokenAssign) THEN
						// Use user name from ArUser template when it exists
						IF(ArUserNameAdr <> 0 AND ArUserPasswordAdr <> 0) THEN
							brsstrcpy(ADR(RFID.PAR.UserName), ArUserNameAdr);					
						END_IF
						RFID.PAR.Password := RFID.DAT.Data;
						ArUserSetToken_0(Execute := FALSE);
						rfid_state := SetToken;
					END_IF
					
					// --------------------------------------------------------------------------------------------------------------------	
					// Read data from serial device
					FRM_read_0.ident := FRM_xopen_0.ident;
					FRM_read_0.enable := 1;
					FRM_read_0();
					TimerTimeout(IN:=1, PT:=2*RFID.PAR.RefreshInterval);
						
					// --------------------------------------------------------------------------------------------------------------------	
					// New data arrived
					IF FRM_read_0.status = 0 THEN
						// Reset timer and buffer
						TimerTimeout(IN:=0);
						brsmemset(ADR(data_read), 0, SIZEOF(data_read));
						brsmemcpy(ADR(data_read), FRM_read_0.buffer, FRM_read_0.buflng);
						// Make sure data is valid
						IF(RFID.PAR.IsConnected AND brsmemcmp(ADR(data_read), ADR('[,'), 2) <> 0) THEN
							// Remove unwanted characters from token data
							idx := 0;
							REPEAT
								IF(brsmemcmp(ADR(data_read)+idx, ADR('['), 1) = 0) THEN
									brsmemcpy(ADR(data_read)+idx, ADR(data_read)+idx+1, brsstrlen(ADR(data_read))-idx);									
								ELSIF(brsmemcmp(ADR(data_read)+idx, ADR(']'), 1) = 0) THEN
									brsmemcpy(ADR(data_read)+idx, ADR(data_read)+idx+1, brsstrlen(ADR(data_read))-idx);									
								ELSIF(brsmemcmp(ADR(data_read)+idx, ADR('$r'), 1) = 0) THEN
									brsmemcpy(ADR(data_read)+idx, ADR(data_read)+idx+1, brsstrlen(ADR(data_read))-idx);									
								ELSIF(brsmemcmp(ADR(data_read)+idx, ADR('$n'), 1) = 0) THEN
									brsmemcpy(ADR(data_read)+idx, ADR(data_read)+idx+1, brsstrlen(ADR(data_read))-idx);
								ELSIF(brsmemcmp(ADR(data_read)+idx, ADR(','), 1) = 0) THEN
									brsmemset(ADR(data_read)+idx, 0, brsstrlen(ADR(data_read))-idx);
								ELSE
									idx := idx + 1;
								END_IF
								UNTIL idx = FRM_read_0.buflng
							END_REPEAT;
							// Check RFID data size
							IF(brsstrlen(ADR(data_read)) >= RFID.PAR.DataMinLen) THEN
								// Maintain stats, move data, identify token
								RFID.DAT.Cnt := RFID.DAT.Cnt + 1;
								RFID.PAR.DataMinLen := brsstrlen(ADR(data_read));
								RFID.VIS.ExecuteLogin := FALSE;
								brsmemset(ADR(RFID.DAT.Data), 0, SIZEOF(RFID.DAT.Data));
								brsstrcpy(ADR(RFID.DAT.Data), ADR(data_read));
								ArUserAuthToken_0(Execute := FALSE);
								IF(brsstrcmp(ADR(tmpTokenOld), ADR(RFID.DAT.Data)) <> 0) THEN
									rfid_state := IdentifyToken;
								END_IF
								tmpTokenOld := RFID.DAT.Data;
							END_IF
						END_IF
						// Release read buffer
						FRM_rbuf_0.buffer := FRM_read_0.buffer;
						FRM_rbuf_0.buflng := FRM_read_0.buflng;
						FRM_rbuf_0.ident := FRM_xopen_0.ident;
						FRM_rbuf_0.enable := 1;
						FRM_rbuf_0();
					// Read response timeout
					ELSIF(TimerTimeout.Q) THEN
						RFID.ERR.Number := 50020;
						RFID.DAT.Status := 'Read response timeout';
						rfid_state := ErrorRFID; 
					// Cyclic read error
					ELSIF FRM_read_0.status <> frmERR_NOINPUT AND FRM_read_0.status <> ERR_FUB_BUSY THEN
						RFID.ERR.Number := FRM_read_0.status;
						RFID.DAT.Status := 'Error in cyclic read';
						rfid_state := ErrorRFID;  
					END_IF
				ELSE
					RFID.CMD.TokenAssign := FALSE;
				END_IF
				// Close USB connection
			ELSIF RFID.PAR.IsConnected = TRUE THEN
				rfid_state := CloseDevice;
			ELSE
				RFID.CMD.TokenAssign := FALSE;
				TimerAutoScan(IN:=0);
			END_IF;
			// Reset old data
			IF(RFID.DAT.Data = '') THEN
				tmpTokenOld := RFID.DAT.Data;
			END_IF
		// --------------------------------------------------------------------------------------------------------------------
		// Set user token
		// --------------------------------------------------------------------------------------------------------------------	
		SetToken:
			ArUserSetToken_0(Execute := TRUE , UserName := RFID.PAR.UserName, Token := RFID.PAR.Password);		

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserSetToken_0.Done AND NOT ArUserSetToken_0.Busy THEN
				ArUserSetPassword_0(Execute := FALSE);
				rfid_state := SetPassword;
			// Error
			ELSIF ArUserSetToken_0.Error THEN
				RFID.ERR.Number := ArUserSetToken_0.ErrorID;
				RFID.ERR.State := rfid_state;
				rfid_state := ErrorRFID;	
			END_IF;
					
		// --------------------------------------------------------------------------------------------------------------------
		// Set password to token data
		// --------------------------------------------------------------------------------------------------------------------					
		SetPassword:		
			ArUserSetPassword_0(Execute := TRUE , UserName := RFID.PAR.UserName , Password := RFID.PAR.Password);			

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserSetPassword_0.Done AND NOT ArUserSetPassword_0.Busy THEN
				IF(RFID.CMD.TokenAssign) THEN
					RFID.DAT.Status := 'Token assigned to user ';
					brsstrcat(ADR(RFID.DAT.Status), ADR(RFID.PAR.UserName));
					RFID.CMD.TokenAssign := FALSE;
				ELSE
					RFID.DAT.Status := 'Token removed from user ';
					brsstrcat(ADR(RFID.DAT.Status), ADR(RFID.PAR.UserName));
					brsstrcat(ADR(RFID.DAT.Status), ADR(' password was set to '));
					brsstrcat(ADR(RFID.DAT.Status), ADR(RFID.PAR.UserName));
					RFID.CMD.TokenRemove := FALSE;
				END_IF
				RFID.VIS.ShowMessageBoxOK := TRUE;
				rfid_state := IdleRFID;
			// Error
			ELSIF ArUserSetPassword_0.Error THEN
				RFID.ERR.Number := ArUserSetPassword_0.ErrorID;
				RFID.ERR.State := rfid_state;
				rfid_state := ErrorRFID;
			END_IF;
			
		// --------------------------------------------------------------------------------------------------------------------
		// Identify user token
		// --------------------------------------------------------------------------------------------------------------------	
		IdentifyToken:
			ArUserAuthToken_0(Execute := TRUE, Token := RFID.DAT.Data);		

			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF ArUserAuthToken_0.Done AND NOT ArUserAuthToken_0.Busy THEN
				IF ArUserAuthToken_0.IsAuthentic THEN
					RFID.PAR.UserName := ArUserAuthToken_0.UserName;
					RFID.PAR.Password := ArUserAuthToken_0.Token;
					// Transfer user name and password from ArUser template when it exists
					IF(ArUserNameAdr <> 0 AND ArUserPasswordAdr <> 0) THEN
						brsstrcpy(ArUserNameAdr, ADR(RFID.PAR.UserName));					
						brsstrcpy(ArUserPasswordAdr, ADR(RFID.PAR.Password));					
					END_IF
					IF(RFID.PAR.AutoLogin) THEN
						RFID.VIS.ExecuteLogin := TRUE;
					END_IF
				ELSE
					RFID.DAT.Status := 'Token is not assigned to any user ';
					RFID.VIS.ShowMessageBoxOK := TRUE;
				END_IF
				rfid_state := IdleRFID;
				// Error
			ELSIF ArUserAuthToken_0.Error THEN
				RFID.ERR.Number := ArUserAuthToken_0.ErrorID;
				RFID.ERR.State := rfid_state;
				rfid_state := ErrorRFID;	
			END_IF;
			
		// -----------------------------------------------------------------------------------------------------------
		// Get USB device list
		// -----------------------------------------------------------------------------------------------------------
		CreateNodeList:  
			UsbNodeListGet_0.enable := 1;
			UsbNodeListGet_0.pBuffer := ADR(node_id_buffer);  
			UsbNodeListGet_0.bufferSize := SIZEOF(node_id_buffer);  
			UsbNodeListGet_0.filterInterfaceClass := asusb_CLASS_VENDOR_SPECIFIC;  
			UsbNodeListGet_0.filterInterfaceSubClass := asusb_CLASS_VENDOR_SPECIFIC;  
			UsbNodeListGet_0;
									
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF UsbNodeListGet_0.status = 0 THEN
				rfid_state := ReadDeviceData;
				// No USB devices found
			ELSIF UsbNodeListGet_0.status = asusbERR_USB_NOTFOUND THEN
				// Unlink old device if it is gone now otherwise IdleRFID for next round
				IF(RFID.PAR.IsConnected) THEN
					rfid_state := CloseDevice;
				ELSE
					rfid_state := IdleRFID;
				END_IF
				// Error
			ELSIF UsbNodeListGet_0.status <> ERR_FUB_BUSY THEN
				rfid_state := ErrorRFID;
			END_IF;
			
		// -----------------------------------------------------------------------------------------------------------
		// Get device information
		// -----------------------------------------------------------------------------------------------------------	
		ReadDeviceData:  				
			UsbNodeGet_0.enable := 1;
			UsbNodeGet_0.nodeId := node_id_buffer[node];  
			UsbNodeGet_0.pBuffer := ADR(usb_data[node]);  
			UsbNodeGet_0.bufferSize := SIZEOF (usb_data[node]);  
			UsbNodeGet_0;
		
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF UsbNodeGet_0.status = 0 THEN
				// Make sure we have enough space to store USB data, proceed with next rfid_state when all devices are detetced
				IF (node = UsbNodeListGet_0.listNodes - 1) OR (node > SIZEOF(usb_data)/SIZEOF(usb_data[0])) THEN
					idx := 0;
					rfid_state := CheckDevice;
					// Get next USB device
				ELSE
					node := node + 1;
				END_IF;
				// Error
			ELSIF UsbNodeGet_0.status <> ERR_FUB_BUSY THEN
				rfid_state := ErrorRFID;  (*error occured*)
			END_IF;
			
		// -----------------------------------------------------------------------------------------------------------
		// Check if device is connected
		// -----------------------------------------------------------------------------------------------------------			
		CheckDevice:
			// Check if device is already linked
			IF(RFID.PAR.IsConnected) THEN
				// Device is already linked, return to IdleRFID state
				IF(brsmemcmp(ADR(usb_data_linked), ADR(usb_data[idx]), SIZEOF(usb_data[idx])) = 0) THEN
					rfid_state := IdleRFID;
				// Check next device
				ELSIF(idx < node) THEN
					idx := idx + 1;
				// Unlink device if it is gone
				ELSE
					rfid_state := CloseDevice;
				END_IF	
			ELSE
				// Make sure devie RFID reader
				IF(usb_data[idx].productId <> 24577 OR usb_data[idx].vendorId <> 1027) THEN
					IF(idx < node) THEN
						idx := idx + 1;
					ELSE
						rfid_state := IdleRFID;						
					END_IF
				ELSE
					rfid_state := OpenDevice;
				END_IF
			END_IF
			
		// -----------------------------------------------------------------------------------------------------------
		// Open device
		// -----------------------------------------------------------------------------------------------------------			
		OpenDevice:
			// Open serial device communication
			FRM_xopen_0.device := ADR(usb_data[0].ifName);
			FRM_xopen_0.enable := 1;
			FRM_xopen_0();		
					
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF FRM_xopen_0.status = 0 THEN
				rfid_init := 0;
				rfid_state := InitDevice;
			// Error
			ELSIF FRM_xopen_0.status <> ERR_FUB_BUSY THEN
				rfid_state := ErrorRFID;  
			END_IF;	
			
		// -----------------------------------------------------------------------------------------------------------
		// Init RFID
		// -----------------------------------------------------------------------------------------------------------				
		InitDevice:
			IF CFG_ACTIVE[rfid_init] <> '' THEN
				data_write := CFG_ACTIVE[rfid_init];
				callback := InitDevice;
				rfid_init := rfid_init + 1;
				rfid_state := DataWrite;
			ELSE
				RFID.PAR.IsConnected := TRUE;
				rfid_state := IdleRFID;
			END_IF;			
		
		// -----------------------------------------------------------------------------------------------------------
		// Empty read buffer before sending next command
		// -----------------------------------------------------------------------------------------------------------			
		DataWrite:
			// Write data to serial device
			FRM_write_0.buffer := ADR(data_write);
			FRM_write_0.buflng := UDINT_TO_UINT(brsstrlen(ADR(data_write)));
			FRM_write_0.ident := FRM_xopen_0.ident;
			FRM_write_0.enable := 1;
			FRM_write_0();		
					
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF FRM_write_0.status = 0 THEN
				IF RFID.PAR.IsConnected THEN
					rfid_state := callback;
				ELSE
					rfid_state := DataRead;
				END_IF
				// Error
			ELSIF FRM_write_0.status <> ERR_FUB_BUSY THEN
				FRM_robuf_0.buffer := FRM_write_0.buffer;
				FRM_robuf_0.buflng := FRM_write_0.buflng;
				FRM_robuf_0.ident := FRM_xopen_0.ident;
				FRM_robuf_0.enable := 1;
				rfid_state := ErrorRFID;  
			END_IF;	
			
		// -----------------------------------------------------------------------------------------------------------
		// Read data from RFID
		// -----------------------------------------------------------------------------------------------------------			
		DataRead:
			// Read data from serial device
			FRM_read_0.ident := FRM_xopen_0.ident;
			FRM_read_0.enable := 1;
			FRM_read_0();
			TimerTimeout(IN:=1, PT:=2*RFID.PAR.RefreshInterval);
					
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF FRM_read_0.status = 0 THEN
				TimerTimeout(IN:=0);
				// Make sure data fits into buffer
				IF(FRM_read_0.buflng < SIZEOF(data_read)) THEN
					brsmemset(ADR(data_write), 0, SIZEOF(data_write));
					brsmemset(ADR(data_read), 0, SIZEOF(data_read));
					brsmemcpy(ADR(data_read), FRM_read_0.buffer, FRM_read_0.buflng);
					// Remove unwanted characters from token data
					idx := 0;
					REPEAT
						IF(brsmemcmp(ADR(data_read)+idx, ADR('['), 1) = 0) THEN
							brsmemcpy(ADR(data_read)+idx, ADR(data_read)+idx+1, brsstrlen(ADR(data_read))-idx);									
						ELSIF(brsmemcmp(ADR(data_read)+idx, ADR(']'), 1) = 0) THEN
							brsmemcpy(ADR(data_read)+idx, ADR(data_read)+idx+1, brsstrlen(ADR(data_read))-idx);									
						ELSIF(brsmemcmp(ADR(data_read)+idx, ADR('$r'), 1) = 0) THEN
							brsmemcpy(ADR(data_read)+idx, ADR(data_read)+idx+1, brsstrlen(ADR(data_read))-idx);									
						ELSIF(brsmemcmp(ADR(data_read)+idx, ADR('$n'), 1) = 0) THEN
							brsmemcpy(ADR(data_read)+idx, ADR(data_read)+idx+1, brsstrlen(ADR(data_read))-idx);
						ELSIF(brsmemcmp(ADR(data_read)+idx, ADR(','), 1) = 0) THEN
							brsmemset(ADR(data_read)+idx, 0, brsstrlen(ADR(data_read))-idx);
						ELSE
							idx := idx + 1;
						END_IF
						UNTIL idx = FRM_read_0.buflng
					END_REPEAT;
					
					IF(brsstrcmp(ADR(data_read), ADR('')) = 0) THEN
						rfid_state := callback;
					ELSE
						RFID.ERR.Number := 50010;
						RFID.DAT.Status := 'RFID response incorrect';
						rfid_state := ErrorRFID;  
					END_IF
			ELSE
				RFID.ERR.Number := 50000;
					RFID.DAT.Status := 'Receive buffer exceeds maximum';
					rfid_state := ErrorRFID;  
				END_IF
				// Release read buffer
				FRM_rbuf_0.buffer := FRM_read_0.buffer;
				FRM_rbuf_0.buflng := FRM_read_0.buflng;
				FRM_rbuf_0.ident := FRM_xopen_0.ident;
				FRM_rbuf_0.enable := 1;
				FRM_rbuf_0();
			// Error from serial read
			ELSIF FRM_read_0.status = frmERR_NOINPUT THEN
			// Error from serial read
			ELSIF FRM_read_0.status <> ERR_FUB_BUSY  AND FRM_read_0.status <> frmERR_NOINPUT THEN
				rfid_state := ErrorRFID; 
			// Read response timeout
			ELSIF(TimerTimeout.Q) THEN
				RFID.ERR.Number := 50020;
				RFID.DAT.Status := 'Read response timeout';
				rfid_state := ErrorRFID;  
			END_IF;	
			
		// -----------------------------------------------------------------------------------------------------------
		// Close device
		// -----------------------------------------------------------------------------------------------------------				
		CloseDevice:
			// Close serial device communication
			FRM_close_0.ident := FRM_xopen_0.ident;
			FRM_close_0.enable := 1;
			FRM_close_0();	
					
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF FRM_close_0.status = 0 THEN
				RFID.PAR.IsConnected := FALSE;
				IF(RFID.CMD.AutoScan) THEN
					rfid_init := 0;
					rfid_state := InitDevice;
				ELSE
					rfid_state := IdleRFID;
				END_IF
				// Error
			ELSIF FRM_close_0.status <> ERR_FUB_BUSY THEN
				rfid_state := ErrorRFID;  
			END_IF;
			
		// -----------------------------------------------------------------------------------------------------------
		// Error state
		// -----------------------------------------------------------------------------------------------------------	
		ErrorRFID:
			// Reset commands
			RFID.CMD.AutoScan := FALSE;
			RFID.CMD.TokenAssign := FALSE;
			RFID.CMD.TokenRemove := FALSE;
			RFID.PAR.IsConnected := FALSE;

			// Reset error
			IF(RFID.CMD.ErrorReset) THEN
				FRM_close_0.ident := FRM_xopen_0.ident;
				FRM_close_0.enable := 1;
				FRM_close_0();	
			
				brsmemset(ADR(RFID.ERR), 0, SIZEOF(RFID.ERR));
				brsmemset(ADR(RFID.DAT), 0, SIZEOF(RFID.DAT));
				RFID.CMD.ErrorReset := FALSE;
				rfid_state := IdleRFID;
			END_IF
	END_CASE;

END_PROGRAM

PROGRAM _EXIT
	REPEAT
		FRM_close_0.ident := FRM_xopen_0.ident;
		FRM_close_0.enable := 1;
		FRM_close_0();	

		UNTIL FRM_close_0.status <> ERR_FUB_BUSY
	END_REPEAT;
END_PROGRAM
