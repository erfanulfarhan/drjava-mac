DrJava for Mac
==============

DrJava (the 2019 release, drjava-beta-20190813-220051) packaged for
today's Macs, with Java 8 included. This is an unofficial build: DrJava
is made by the JavaPLT group at Rice University, and this package only
adds the Mac fixes listed below.

Latest version, source and help:
https://github.com/erfanulfarhan/drjava-mac


Install
-------
1. Drag DrJava into your Applications folder.
2. Open DrJava. The first time, macOS says it can't verify the app,
   because it isn't notarized by Apple. Click Done.
3. Open System Settings, go to Privacy & Security, scroll down and click
   Open Anyway next to the message about DrJava. Confirm with your
   password or Touch ID.

After that DrJava opens normally. On macOS 14 or older, right-click
DrJava, choose Open, then click Open, instead of step 3.


Intel Macs
----------
The Java 8 inside this app is for Apple Silicon Macs (M1 and newer). On
an Intel Mac, install Amazon Corretto 8 for macOS x64 first. DrJava
finds it by itself:
https://docs.aws.amazon.com/corretto/latest/corretto-8-ug/downloads-list.html


What's different from the official download
-------------------------------------------
- Java 8 is inside the app (Amazon Corretto 8.504.04.1, without its
  source code archive). DrJava does not work with Java 9 or later.
- Compile actually works. On a Mac with no separate JDK installed, DrJava
  uses its own built-in compiler but points it at the wrong core library,
  so it says "Compilation completed." without making a .class file, and
  Run then complains the document is out of sync. The launcher gives the
  compiler Java 8's real library.
- Sharp text on Retina screens. On recent macOS, Java 8 can't work out
  which screen it is on, so it draws at half resolution and DrJava looks
  blurry. The app's launcher fixes that before Java starts.
- The debugger port only accepts connections from your own Mac. With
  Java 8, DrJava otherwise opens it to everyone on the same network.


If DrJava won't open
--------------------
DrJava writes a log to ~/Library/Logs/DrJava.log.


Licenses
--------
Amazon Corretto is licensed under the GNU General Public License,
version 2, with the Classpath Exception. Its license files are inside
DrJava.app/Contents/PlugIns/Java8.jdk/Contents/Home, and the source code
of this exact version is at
https://github.com/corretto/corretto-8/releases/tag/8.504.04.1

DrJava is open source under the following license:

