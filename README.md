BoomBox
=======
A macos menubar app that monitors itunes track/equalizer settings and allows to change the EQ Preset. Supports Growl and Notification Center (via growl 2.0 under 10.8)

The app was tested ( a little ) under 10.8 but should work under 10.7 as well.
The binary available for download is NOT signed with a deveoper certificate at the moment.

![Screenshot](http://github.com/Daij-Djan/BoomBox/raw/master/ScreenShot.png)

history: 

- 0.7 **Drastically** reduced CPU Usage - I was using a timer to poll itunes too often. Now I only poll the equalizer when it is open and frontmost and look for song change notifications<br/>
Added iVersion for update checking<br/>
It doesnt use Growl anymore put nativly supports the Notification center.

- 0.6.1 adds a quit menu item to boombox WHEN itunes isnt running. (Earlier, it was only there when active)

- 0.6 fixes crucial bug that kept itunes open and restarted it when quit! I think this is a bug in apple's scripting bridge though...

- 0.5 initial release
