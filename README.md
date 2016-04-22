# LibreRead-iOS
Libre iOS start Project

This project is NOT supported, maintained or in any ways affiliated with or by Abbott. Use at your own risk. Dont make medical decisions based on readings of this app, always use certified original products to make decissions about your blood glucose levels or insulin dosage!

This is may first attemp to bring the Abbott fresstyle Libre System to iOS.
You need a DiY nfc to ble adapter to get this working! Look at http://unendlichkeit.net for my own project or wait until the open source hardware project blueReader can be bought.
The Sources for the ble firmware can be found within my repos: https://github.com/SandraK82/ and on mbed: https://developer.mbed.org/users/SandraK/

Whats working so far:
- [x] read Sensor data via https://github.com/SandraK82/libBlueReader-iOS
- [x] show Graphical data with https://github.com/danielgindi/Charts
- [x] push data to TodayWidget via https://github.com/mutualmobile/MMWormhole
- [x] show graphical data on TodayWidget
- [x] continue reading bg data in the background
- [ ] save Sensor data
- [ ] show old sensor data
- [ ] do only incremental updates of sensor data
