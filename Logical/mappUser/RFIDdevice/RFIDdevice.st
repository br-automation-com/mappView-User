// --------------------------------------------------------------------------------------------------------------------
// This task allows user login with RFID tokens. The following functions are implemneted
// - Assign or remove token from user
// Version 1.1
// -----------------------------------------------------------------------------------------------------------
PROGRAM _INIT
	// -----------------------------------------------------------------------------------------------------------
	// Start auto scan, set default parameters
	RFID.CMD.ReaderEnable := TRUE;				// AutoScan for RFID reader and token data
	RFID.PAR.AutoLogin := TRUE;					// Auto login user when token is detected
	RFID.PAR.RefreshInterval := 50;				// Read data every 500ms
	RFID.PAR.DataMinLen := 16;					// Mimimum length of RFID data, everything shorter will be ignored	

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
			IF RFID.CMD.TokenRemove THEN
				ArUserSetToken_0(Execute := FALSE);
				RFID.PAR.Password := RFID.PAR.UserName;
				rfid_state := SetToken;
			END_IF
			
			// Refresh USB data when enabled
			IF RFID.CMD.ReaderEnable THEN
				// --------------------------------------------------------------------------------------------------------------------	
				// Get new RFID data
				TimerAutoScan(IN:=1, PT:=RFID.PAR.RefreshInterval);
				IF TimerAutoScan.Q THEN
					TimerAutoScan(IN:=0);
					node := 0;
					IF(RFID.DAT.IsConnected) THEN
						// Reader 5E9010.29 needs a request before reading token data
						IF(RFID.DAT.Type = RFID_5E9010_29) THEN
							data_write := REQ_ACTIVE;
							callback := IdleRFID;
							rfid_state := DataWrite;
						// Make sure reader 5E9030 is still connected
						ELSE
							brsmemset(ADR(usb_data), 0, SIZEOF(usb_data));
							rfid_state := CreateNodeList;
						END_IF
					// Search for RFID reader when not connected
					ELSE
						brsmemset(ADR(usb_data), 0, SIZEOF(usb_data));
						rfid_state := CreateNodeList;
					END_IF
				END_IF
				
				// --------------------------------------------------------------------------------------------------------------------	
				// When RFID reader is connected
				IF RFID.DAT.IsConnected = TRUE THEN
					// --------------------------------------------------------------------------------------------------------------------	
					// Assign token to user
					IF RFID.CMD.TokenAssign THEN
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
						IF RFID.DAT.IsConnected AND brsmemcmp(ADR(data_read), ADR('[,'), 2) <> 0 AND brsmemcmp(ADR(data_read), ADR('PiccRemove:'), 11) <> 0 THEN
							// Remove unwanted characters from token data
							idx := 0;
							REPEAT
								IF(brsmemcmp(ADR(data_read), ADR('PiccSelect:'), 11) = 0) THEN
									brsmemcpy(ADR(data_read)+idx, ADR(data_read)+idx+11, brsstrlen(ADR(data_read))-idx);									
								ELSIF(brsmemcmp(ADR(data_read)+idx, ADR(' '), 1) = 0) THEN
									brsmemcpy(ADR(data_read)+idx, ADR(data_read)+idx+1, brsstrlen(ADR(data_read))-idx);									
								ELSIF(brsmemcmp(ADR(data_read)+idx, ADR('['), 1) = 0) THEN
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
							IF brsstrlen(ADR(data_read)) >= RFID.PAR.DataMinLen THEN
								// Maintain stats, move data, identify token
								RFID.DAT.Cnt := RFID.DAT.Cnt + 1;
								RFID.VIS.ExecuteLogin := FALSE;
								brsmemset(ADR(RFID.DAT.Data), 0, SIZEOF(RFID.DAT.Data));
								brsstrcpy(ADR(RFID.DAT.Data), ADR(data_read));
								ArUserAuthToken_0(Execute := FALSE);
								IF(brsstrcmp(ADR(tmpTokenOld), ADR(RFID.DAT.Data)) <> 0) THEN
									rfid_state := IdentifyToken;
								END_IF
								tmpTokenOld := RFID.DAT.Data;
							END_IF					
						// Reset old token when it was removed from reader
						ELSIF RFID.DAT.IsConnected AND brsmemcmp(ADR(data_read), ADR('PiccRemove:'), 11) = 0 THEN
							tmpTokenOld := '';
						END_IF
						
						// Release read buffer
						FRM_rbuf_0.buffer := FRM_read_0.buffer;
						FRM_rbuf_0.buflng := FRM_read_0.buflng;
						FRM_rbuf_0.ident := FRM_xopen_0.ident;
						FRM_rbuf_0.enable := 1;
						FRM_rbuf_0();					
					// Read response timeout
					ELSIF TimerTimeout.Q THEN
						// Ignore timeout for 5E9030
						IF RFID.DAT.Type <> RFID_5E9030_29 THEN
							RFID.ERR.Number := 50020;
							RFID.DAT.Status := 'Read response timeout';
							rfid_state := ErrorRFID;
						END_IF			
					// Cyclic read error
					ELSIF FRM_read_0.status <> frmERR_NOINPUT AND FRM_read_0.status <> ERR_FUB_BUSY THEN
						RFID.ERR.Number := FRM_read_0.status;
						RFID.DAT.Status := 'Error in cyclic read';
						rfid_state := ErrorRFID;  
					END_IF
				ELSE
					RFID.CMD.TokenAssign := FALSE;
				END_IF
				
			// --------------------------------------------------------------------------------------------------------------------	
			// Close USB connection
			ELSIF RFID.DAT.IsConnected = TRUE THEN
				rfid_state := CloseDevice;
				
			// --------------------------------------------------------------------------------------------------------------------	
			// Function is disabled
			ELSE
				RFID.CMD.TokenAssign := FALSE;
				TimerAutoScan(IN:=0);
				RFID.DAT.Status := 'Disabled';
			END_IF;
			
			// --------------------------------------------------------------------------------------------------------------------	
			// Reset old data
			IF RFID.DAT.Data = '' THEN
				tmpTokenOld := RFID.DAT.Data;
			END_IF
			
			// --------------------------------------------------------------------------------------------------------------------	
			// Reset error
			IF RFID.CMD.ErrorReset  THEN
				brsmemset(ADR(RFID.DAT.Data), 0, SIZEOF(RFID.DAT.Data));
				RFID.CMD.ErrorReset := FALSE;
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
				RFID.DAT.Status := 'Error assigning token';
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
					RFID.DAT.Status := 'Token was assigned to user ';
					brsstrcat(ADR(RFID.DAT.Status), ADR(RFID.PAR.UserName));
					RFID.CMD.TokenAssign := FALSE;
				ELSE
					RFID.DAT.Status := 'Token was removed from user ';
					brsstrcat(ADR(RFID.DAT.Status), ADR(RFID.PAR.UserName));
					brsstrcat(ADR(RFID.DAT.Status), ADR(' password is set to '));
					brsstrcat(ADR(RFID.DAT.Status), ADR(RFID.PAR.Password));
					RFID.CMD.TokenRemove := FALSE;
				END_IF
				RFID.VIS.ShowMessageBoxOK := TRUE;
				rfid_state := IdleRFID;
			// Error
			ELSIF ArUserSetPassword_0.Error THEN
				RFID.DAT.Status := 'Error setting user password';
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
					RFID.DAT.Status := 'Token from user ';
					brsstrcat(ADR(RFID.DAT.Status), ADR(RFID.PAR.UserName));
					brsstrcat(ADR(RFID.DAT.Status), ADR(' identified'));
					// Transfer user name and password from ArUser template when it exists
					IF(ArUserNameAdr <> 0 AND ArUserPasswordAdr <> 0) THEN
						brsstrcpy(ArUserNameAdr, ADR(RFID.PAR.UserName));					
						brsstrcpy(ArUserPasswordAdr, ADR(RFID.PAR.Password));					
					END_IF
					IF(RFID.PAR.AutoLogin) THEN
						RFID.VIS.ExecuteLogin := TRUE;
						brsstrcat(ADR(RFID.DAT.Status), ADR(' and logged in'));
					END_IF
				ELSE
					RFID.DAT.Status := 'Token is not assigned to any user ';
					RFID.VIS.ShowMessageBoxOK := TRUE;
				END_IF
				rfid_state := IdleRFID;
				// Error
			ELSIF ArUserAuthToken_0.Error THEN
				RFID.DAT.Status := 'Error identifying token';
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
			UsbNodeListGet_0.filterInterfaceClass := 0;  
			UsbNodeListGet_0.filterInterfaceSubClass := 0;  
			UsbNodeListGet_0;
									
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF UsbNodeListGet_0.status = 0 THEN
				rfid_state := ReadDeviceData;
			// No USB devices found
			ELSIF UsbNodeListGet_0.status = asusbERR_USB_NOTFOUND THEN
				// Unlink old device if it is gone now otherwise report error
				IF(RFID.DAT.IsConnected) THEN
					rfid_state := CloseDevice;
				ELSE
					RFID.ERR.Number := UsbNodeListGet_0.status;
					RFID.DAT.Status := 'No USB reader detected';
					rfid_state := ErrorRFID;  
				END_IF
			// Error
			ELSIF UsbNodeListGet_0.status <> ERR_FUB_BUSY THEN
				RFID.DAT.Status := 'Error generating USB node list';
				RFID.ERR.Number := UsbNodeListGet_0.status;
				RFID.ERR.State := rfid_state;
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
				RFID.ERR.Number := UsbNodeGet_0.status;
				RFID.ERR.State := rfid_state;
				rfid_state := ErrorRFID;
			END_IF;
			
		// -----------------------------------------------------------------------------------------------------------
		// Check if device is connected
		// -----------------------------------------------------------------------------------------------------------			
		CheckDevice:
			// Check if device is already linked
			IF RFID.DAT.IsConnected THEN
				// Device is already linked, return to IdleRFID state
				IF brsmemcmp(ADR(usb_data_linked), ADR(usb_data[idx]), SIZEOF(usb_data[idx])) = 0 THEN
					rfid_state := IdleRFID;
				// Check next device
				ELSIF idx < node THEN
					idx := idx + 1;
				// Reader was disconnected
				ELSE
					RFID.DAT.Status := 'Reader disconnected';
					RFID.DAT.IsConnected := FALSE;
					RFID.ERR.Number := ERR_RFID_DISCONNECTED;
					RFID.ERR.State := rfid_state;
					rfid_state := ErrorRFID;
				END_IF	
			ELSE
				// Device is RFID reader type 5E9010.29
				IF usb_data[idx].productId = DEV_PRODUCT_ID[RFID_5E9010_29] AND usb_data[idx].vendorId = DEV_VENDOR_ID[RFID_5E9010_29] THEN
					// Copy configuration data and request string
					brsmemcpy(ADR(usb_data_linked), ADR(usb_data[idx]), SIZEOF(usb_data_linked));
					brsmemset(ADR(CFG_ACTIVE), 0, SIZEOF(CFG_ACTIVE));
					brsmemcpy(ADR(CFG_ACTIVE), ADR(CFG_5E9010_29), SIZEOF(CFG_5E9010_29));
					REQ_ACTIVE := REQ_5E9010_29;
					RFID.DAT.Type := RFID_5E9010_29;
					RFID.DAT.Status := 'Reader 5E9010 connected';
					rfid_state := OpenDevice;
					// Device is RFID reader type 5E9030.29
				ELSIF usb_data[idx].productId = DEV_PRODUCT_ID[RFID_5E9030_29] AND usb_data[idx].vendorId = DEV_VENDOR_ID[RFID_5E9030_29] THEN
					// Copy configuration data and request string
					brsmemcpy(ADR(usb_data_linked), ADR(usb_data[idx]), SIZEOF(usb_data_linked));
					brsmemset(ADR(CFG_ACTIVE), 0, SIZEOF(CFG_ACTIVE));
					brsmemcpy(ADR(CFG_ACTIVE), ADR(CFG_5E9030_29), SIZEOF(CFG_5E9030_29));
					RFID.DAT.Type := RFID_5E9030_29;
					RFID.DAT.Status := 'Reader 5E9030 connected';
					rfid_state := OpenDevice;
				ELSE
					IF idx < node THEN
						idx := idx + 1;
					ELSE
						RFID.DAT.Status := 'No USB reader detected';
						rfid_state := IdleRFID;						
					END_IF
				END_IF
			END_IF
			
		// -----------------------------------------------------------------------------------------------------------
		// Open device
		// -----------------------------------------------------------------------------------------------------------			
		OpenDevice:
			// Open serial device communication
			FRM_xopen_0.device := ADR(usb_data_linked.ifName);
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
			// Send next configuration data
			IF CFG_ACTIVE[rfid_init] <> '' THEN
				data_write := CFG_ACTIVE[rfid_init];
				callback := InitDevice;
				rfid_init := rfid_init + 1;
				rfid_state := DataWrite;
			// Finish sending configuration
			ELSE
				RFID.DAT.IsConnected := TRUE;
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
				IF RFID.DAT.IsConnected THEN
					rfid_state := callback;
				ELSE
					TimerTimeout(IN:=0);
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
			TimerTimeout(IN:=1, PT:=100);
					
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF FRM_read_0.status = 0 THEN
				TimerTimeout(IN:=0);
				// Make sure data fits into buffer
				IF FRM_read_0.buflng < SIZEOF(data_read) THEN
					brsmemset(ADR(data_write), 0, SIZEOF(data_write));
					brsmemset(ADR(data_read), 0, SIZEOF(data_read));
					brsmemcpy(ADR(data_read), FRM_read_0.buffer, FRM_read_0.buflng);
					// Remove unwanted characters from token data
					idx := 0;
					REPEAT
						IF(brsmemcmp(ADR(data_read)+idx, ADR('['), 1) = 0) THEN
							brsmemcpy(ADR(data_read)+idx, ADR(data_read)+idx+1, brsstrlen(ADR(data_read))-idx);									
						ELSIF(brsmemcmp(ADR(data_read)+idx, ADR(' '), 1) = 0) THEN
							brsmemcpy(ADR(data_read)+idx, ADR(data_read)+idx+1, brsstrlen(ADR(data_read))-idx);									
						ELSIF(brsmemcmp(ADR(data_read)+idx, ADR('*'), 1) = 0) THEN
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
					
					// Response for 5E9010 should be empty, Initial response for 5E9030 can be ignored
					IF brsstrcmp(ADR(data_read), ADR('')) = 0 OR RFID.DAT.Type = RFID_5E9030_29 THEN
						rfid_state := callback;
					ELSE
						RFID.ERR.Number := ERR_RFID_RESPONSE;
						RFID.DAT.Status := 'RFID response incorrect';
						rfid_state := ErrorRFID;  
					END_IF
				// Read data exceeds buffer
				ELSE
					RFID.ERR.Number := ERR_RFID_BUFFER;
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
			ELSIF FRM_read_0.status <> ERR_FUB_BUSY  AND FRM_read_0.status <> frmERR_NOINPUT THEN
				rfid_state := ErrorRFID; 
			// Read response timeout
			ELSIF(TimerTimeout.Q) THEN
				// Ignore timeout for 5E9030
				IF RFID.DAT.Type = RFID_5E9030_29 THEN
					rfid_state := callback;
				ELSE
					RFID.ERR.Number := ERR_RFID_READ_TIMEOUT;
					RFID.DAT.Status := 'Read response timeout';
					rfid_state := ErrorRFID;  
				END_IF;	
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
				RFID.DAT.IsConnected := FALSE;
				RFID.DAT.Type := RFID_NONE;
				IF(RFID.CMD.ReaderEnable) THEN
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
			RFID.CMD.ReaderEnable := FALSE;
			RFID.CMD.TokenAssign := FALSE;
			RFID.CMD.TokenRemove := FALSE;
			RFID.DAT.IsConnected := FALSE;

			// Reset error
			IF RFID.CMD.ErrorReset THEN
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
