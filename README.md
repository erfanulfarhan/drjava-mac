<p align="center"><img src="icon/drjava.png" width="96" alt="DrJava icon"></p>

# DrJava for Mac

DrJava, the Java editor many university courses use, packaged for today's Macs. Java 8 is built in, compiling works, and text is sharp on Retina screens. Download it, drag it to Applications, allow it once, and you're writing Java.

<p align="center">
  <a href="https://github.com/erfanulfarhan/drjava-mac/releases/latest/download/DrJava-for-Mac.zip"><img src="https://img.shields.io/badge/Download-DrJava%20for%20Mac-2f6fde?style=for-the-badge" alt="Download DrJava for Mac"></a>
  <br>
  <sub>One click downloads <code>DrJava-for-Mac.zip</code> (72 MB). macOS 10.13 or later; Apple silicon has Java 8 built in.</sub>
</p>

## Install

Watch the two-minute walkthrough: [DrJava on a Mac in two minutes!](https://youtu.be/MBTZ_kf3ZDo)

1. [Download DrJava-for-Mac.zip](https://github.com/erfanulfarhan/drjava-mac/releases/latest/download/DrJava-for-Mac.zip) and double-click it. Your Mac unzips it for you.
2. Open the **DrJava for Mac** folder and drag **DrJava** into **Applications**.
3. Open DrJava. The first time, macOS says **"DrJava" Not Opened**, because the app isn't notarized by Apple. Click **Done**.
4. Open **System Settings → Privacy & Security**, scroll down, click **Open Anyway** next to the message about DrJava, and confirm with Touch ID or your password.

You only do this once; after that DrJava opens like any other app. On macOS 14 or older, right-click DrJava and choose **Open** instead of step 4.

### Intel Macs

The Java 8 inside the app is for Apple silicon (M1 and newer). On an Intel Mac, install [Amazon Corretto 8 for macOS x64](https://docs.aws.amazon.com/corretto/latest/corretto-8-ug/downloads-list.html) first. DrJava finds it by itself.

## What's different from the official download

DrJava's last release (drjava-beta-20190813-220051) needs Java 8 and was made before Apple silicon. On a new Mac it has four problems, and this build fixes each one:

- **Java 8 is inside the app** (Amazon Corretto 8.504.04.1). DrJava doesn't work with Java 9 or later, and new Macs don't come with Java at all.
- **Compile actually works.** Without a separate JDK, DrJava's built-in compiler is pointed at the wrong core library, so it says "Compilation completed." without making a `.class` file, and Run then complains the document is out of sync. The launcher hands the compiler Java 8's real library.
- **Sharp text on Retina screens.** On recent macOS, Java 8 can't tell which screen it is on, so it draws at half resolution and DrJava looks blurry. The launcher fixes that before Java starts.
- **The debugger stays private.** With Java 8, DrJava's debugger port listens on every network your Mac is on. This build keeps it on `127.0.0.1`.

If DrJava won't open, its log is at `~/Library/Logs/DrJava.log`.

## Build it yourself

You need the Xcode Command Line Tools, the official [drjava-beta-20190813-220051.jar](https://sourceforge.net/projects/drjava/files/1.%20DrJava%20Stable%20Releases/drjava-beta-20190813-220051/) and [Amazon Corretto 8 for Apple silicon](https://docs.aws.amazon.com/corretto/latest/corretto-8-ug/downloads-list.html) (the macOS aarch64 .tar.gz, unpacked).

```
git clone https://github.com/erfanulfarhan/drjava-mac.git
cd drjava-mac
DRJAVA_JAR=~/Downloads/drjava-beta-20190813-220051.jar \
JDK=~/Library/Java/JavaVirtualMachines/amazon-corretto-8.jdk \
./build.sh
```

`build.sh` checks the jar against SourceForge's published MD5, compiles the launcher for Apple silicon and Intel, patches the debugger address, copies Java 8 in (without its 50 MB source archive), signs the app ad hoc and zips it, with the Read Me, to `~/Downloads/DrJava-for-Mac.zip` (set `OUT` to change that).

| File | What it is |
| --- | --- |
| `launcher.m` | The app's native launcher: starts DrJava on the bundled Java 8 (or an installed one), fixes the Retina scale and the compiler's library path |
| `patch_jar.py` | Changes one string in DrJava's `MainJVM` class so the debugger listens on `127.0.0.1` only |
| `build.sh` | Builds the app and the zip |
| `Info.plist` | The app's bundle settings |
| `readme.txt` | The Read Me that ships in the zip |

## Licenses

- The build scripts in this repository: [MIT](LICENSE).
- DrJava: BSD license, by the JavaPLT group at Rice University. Its license text ships in the zip's Read Me.
- Amazon Corretto 8: GNU GPL version 2 with the Classpath Exception. The source code of the bundled version is at [corretto-8 release 8.504.04.1](https://github.com/corretto/corretto-8/releases/tag/8.504.04.1).

This is an unofficial build. It isn't made or endorsed by Rice University, Amazon or Apple.
