### BlinkMSequencer2 (old)

The below BlinkMSequencer2 will likely not work, as things have evolved 
much in 15 years. 

A. Bundle for Mac OS X
  1. Open BlinkMSequencer2 in Processing
  2. Choose File -> Export Application, choose "Mac OS X"
  3. In Finder, open linkm/processing_apps/BlinkMSequencer2/application.macosx
  4. Add Icon:
  4a.  Right-click "BlinkMSequencer2.app", choose "Get Info"
  4b.  Open "linkm/tools/bundle_bits/thingm_log-10.png" in Preview.
  4c.  Select All, copy, then select icon in Info inspector, and paste
  5. Right-click "BlinkMSequencer2.app", choose "Compress ..."
  6. Rename resulting zip as "BlinkMSequencer2_macosx.zip"
  7. Publish release

B. Bundle for Windows:
  1. Open BlinkMSequencer2 in Processing
  2. Choose File -> Export Application, choose your "Windows"
  3. Bundle with Java with these 5 command-line commands:
  ```
     cd linkm/processing_apps/BlinkMSequencer2/application.windows
     unzip ../../../tools/bundle_bits/java_from_arduino_0018_win.zip
     cd ..
     mv application.windows BlinkMSequencer2_windows
     zip -r BlinkMSequencer2_windows.zip BlinkMSequencer2_windows
  ```
  4. Publish release

C. Bundle for Linux:
  1. Open BlinkMSequencer2 in Processing
  2. Choose File -> Export Application, choose "Linux"
  3. Bundle with the following 3 command-line commands:
  ```
     cd linkm/processing_apps/BlinkMSequencer2
     mv application.linux BlinkMSequencer2_linux
     tar cvzf BlinkMSequencer2_linux.tar.gz BlinkMSequencer2_linux
  ```
  4. Publish release
