// Native launcher for DrJava.app ("DrJava for Mac").
//
// DrJava (beta-20190813) needs Java 8; it does not work with Java 9 or later. This launcher loads
// Java 8 into its own process through Java's libjli. It uses the copy inside the app
// (Contents/PlugIns/Java8.jdk, Apple Silicon) and falls back to a Java 8 installed on the Mac,
// which is what Intel Macs use. Running in-process lets it fix one thing before Java starts:
//
// Java 8 finds the screen it is on by comparing -[NSNumber pointerValue] with the display ID.
// Newer macOS answers pointerValue with NULL for plain integer numbers, so Java never finds the
// screen, assumes a scale of 1 and draws everything at half resolution: blurry on Retina.
// Below, pointerValue returns the integer again, as older macOS did. Later Java versions
// compare with unsignedIntValue instead and don't need this.
//
// `DrJava.app/Contents/MacOS/DrJava --print-java` prints the Java it would use and exits.
// Built by build.sh.
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <limits.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <unistd.h>

static const char *JAVA8_DOWNLOADS =
    "https://docs.aws.amazon.com/corretto/latest/corretto-8-ug/downloads-list.html";

typedef int (*JLILaunch)(int argc, char **argv, int jargc, const char **jargv,
                         int appclassc, const char **appclassv,
                         const char *fullversion, const char *dotversion,
                         const char *pname, const char *lname,
                         unsigned char javaargs, unsigned char cpwildcard,
                         unsigned char javaw, int ergo);

static JLILaunch jli_launch;
static IMP original_pointer_value;

static int launch(int argc, char **argv) {
    return jli_launch(argc, argv, 0, NULL, 0, NULL, "1.8", "1.8", "java", "java", 0, 1, 0, 0);
}

static void *integer_pointer_value(id self, SEL cmd) {
    const char *type = [self objCType];
    if (type && type[0] && strchr("cislqCISLQB", type[0]))
        return (void *)(uintptr_t)[self unsignedLongLongValue];
    return ((void *(*)(id, SEL))original_pointer_value)(self, cmd);
}

static void fix_screen_lookup(void) {
    Class number = objc_getClass("__NSCFNumber") ?: [NSNumber class];
    SEL sel = @selector(pointerValue);
    Method inherited = class_getInstanceMethod(number, sel);
    if (!inherited) return;
    original_pointer_value = method_getImplementation(inherited);
    if (!class_addMethod(number, sel, (IMP)integer_pointer_value, method_getTypeEncoding(inherited)))
        method_setImplementation(inherited, (IMP)integer_pointer_value);
}

// Loads libjli from a Java home. NULL if it isn't there or is built for the other kind of Mac.
static JLILaunch load_jli(const char *java_home) {
    char path[PATH_MAX];
    snprintf(path, sizeof path, "%s/jre/lib/jli/libjli.dylib", java_home);
    if (access(path, R_OK) != 0) snprintf(path, sizeof path, "%s/lib/jli/libjli.dylib", java_home);
    void *lib = dlopen(path, RTLD_NOW | RTLD_GLOBAL);
    return lib ? (JLILaunch)dlsym(lib, "JLI_Launch") : NULL;
}

// Asks macOS for an installed Java 8, as `/usr/libexec/java_home -v 1.8` does.
static int find_installed_java8(char *out, size_t size) {
    FILE *p = popen("/usr/libexec/java_home -v 1.8 2>/dev/null", "r");
    if (!p) return 0;
    int ok = fgets(out, (int)size, p) != NULL;
    pclose(p);
    out[strcspn(out, "\n")] = '\0';
    return ok && out[0] == '/';
}

// Shows an alert and returns whether the first button was clicked.
static int alert(const char *title, const char *message, const char *button, const char *cancel) {
    CFStringRef t = CFStringCreateWithCString(NULL, title, kCFStringEncodingUTF8);
    CFStringRef m = CFStringCreateWithCString(NULL, message, kCFStringEncodingUTF8);
    CFStringRef b = CFStringCreateWithCString(NULL, button, kCFStringEncodingUTF8);
    CFStringRef c = CFStringCreateWithCString(NULL, cancel, kCFStringEncodingUTF8);
    CFOptionFlags response = kCFUserNotificationCancelResponse;
    CFUserNotificationDisplayAlert(0, kCFUserNotificationStopAlertLevel, NULL, NULL, NULL,
                                   t, m, b, c, NULL, &response);
    CFRelease(t);
    CFRelease(m);
    CFRelease(b);
    CFRelease(c);
    return (response & 0x3) == kCFUserNotificationDefaultResponse;
}

int main(int argc, char **argv) {
    // On macOS, libjli runs main() a second time on a new thread, passing the arguments built
    // below, so that the first thread can serve the Cocoa event loop. Pass those straight through.
    if (jli_launch) return launch(argc, argv);

    char exe[PATH_MAX], contents[PATH_MAX];
    uint32_t size = sizeof exe;
    if (_NSGetExecutablePath(exe, &size) != 0 || !realpath(exe, contents)) return 1;
    char *slash = strrchr(contents, '/');                       // .../Contents/MacOS/DrJava
    if (!slash) return 1;
    char name[PATH_MAX];
    strlcpy(name, slash + 1, sizeof name);                      // "DrJava"
    *slash = '\0';                                              // .../Contents/MacOS
    if (!(slash = strrchr(contents, '/'))) return 1;
    *slash = '\0';                                              // .../DrJava.app/Contents

    char java[PATH_MAX];
    snprintf(java, sizeof java, "%s/PlugIns/Java8.jdk/Contents/Home", contents);
    jli_launch = load_jli(java);
    if (!jli_launch && find_installed_java8(java, sizeof java)) jli_launch = load_jli(java);

    if (argc > 1 && strcmp(argv[1], "--print-java") == 0) {
        printf("%s\n", jli_launch ? java : "no usable Java 8");
        return jli_launch ? 0 : 1;
    }
    if (!jli_launch) {
        if (alert("DrJava needs Java 8",
                  "On an Intel Mac, install Amazon Corretto 8 for macOS x64 first, "
                  "then open DrJava again.",
                  "Get Java 8", "Cancel"))
            execl("/usr/bin/open", "open", JAVA8_DOWNLOADS, (char *)NULL);
        return 1;
    }

    fix_screen_lookup();

    // Keep the console output, which a Finder launch would otherwise throw away.
    const char *home = getenv("HOME");
    if (home) {
        char log[PATH_MAX];
        snprintf(log, sizeof log, "%s/Library/Logs/%s.log", home, name);
        freopen(log, "a", stdout);
        freopen(log, "a", stderr);
    }

    static char dock_name[PATH_MAX], dock_icon[PATH_MAX], jar[PATH_MAX];
    snprintf(dock_name, sizeof dock_name, "-Xdock:name=%s", name);
    snprintf(dock_icon, sizeof dock_icon, "-Xdock:icon=%s/Resources/DrJava.icns", contents);
    snprintf(jar, sizeof jar, "%s/Resources/drjava.jar", contents);

    // DrJava compiles with the javac bundled in its own jar and, finding no other JDK, passes that
    // jar as javac's -bootclasspath. javac then can't find java.lang, stops with a fatal error that
    // DrJava swallows, and DrJava still reports "Compilation completed." with no .class written.
    // DrJava reads drjava.bootclasspath for exactly this, so point it at Java 8's own core jars.
    static char boot[8 * PATH_MAX];
    strlcpy(boot, "-Ddrjava.bootclasspath=", sizeof boot);
    const char *core[] = {"resources", "rt", "sunrsasign", "jsse", "jce", "charsets", "jfr"};
    int added = 0;
    for (size_t i = 0; i < sizeof core / sizeof *core; i++) {
        char p[PATH_MAX];
        snprintf(p, sizeof p, "%s/jre/lib/%s.jar", java, core[i]);
        if (access(p, R_OK) != 0) snprintf(p, sizeof p, "%s/lib/%s.jar", java, core[i]);
        if (access(p, R_OK) != 0) continue;
        if (added++) strlcat(boot, ":", sizeof boot);
        strlcat(boot, p, sizeof boot);
    }

    char **args = calloc((size_t)argc + 7, sizeof *args);
    int n = 0;
    args[n++] = argv[0];
    args[n++] = dock_name;
    args[n++] = dock_icon;
    if (added) args[n++] = boot;
    args[n++] = "-jar";
    args[n++] = jar;
    for (int i = 1; i < argc; i++)
        if (strncmp(argv[i], "-psn_", 5) != 0) args[n++] = argv[i];  // skip Finder's process number
    return launch(n, args);
}
