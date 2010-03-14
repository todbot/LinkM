LinkMv1 Testing Script            -- 20100314, ThingM, Tod E. Kurt
======================

Note:
-----
- This script assumes a Windows computer is the USB host.  
- A Linux computer may also be used (with optional file supplied)
- The "linkm_load.bat" batch file runs in a loop to speed testing


Script:
-------
1. Connect shorting jumper across pins 'o' and '-' on "isp" header

2. Plug LinkM board into USB host machine
   
3. Observe LED1 "status" should light and stay lit

4. Observe LinkM unit properly negotiates with USB host
   - LinkM unit should appear in host's USB device list as HID device with:
     - USB VendorID = 0x20A0
     - USB DeviceID = 0x4110 
     - USB VendorName = "ThingM"
     - USB DeviceName = "LinkMBoot"

5. Run Windows batch file "linkm_load.bat"
     - Observe the screen print out the message:
         Page size   = 64 (0x40)
         Device size = 8192 (0x2000); 6144 bytes remaining
         Uploading 4224 (0x1080) bytes starting at 0 (0x0)
         0x01000 ... 0x01080
         Flashing done.
         Switching from LinkMBoot to LinkM...
      - It should NOT say "Error opening LinkM"

6. Observe LED2 "enable" should light and stay lit

7. Observe LinkM unit switches to "LinkM" mode and reconnects with USB host as:
     - USB VendorID = 0x20A0
     - USB DeviceID = 0x4110 
     - USB VendorName = "ThingM"
     - USB DeviceName = "LinkM"

8. If any of the above observations fail, mark unit FAIL, other mark PASS



