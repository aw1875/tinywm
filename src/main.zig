const x = @cImport({
    @cInclude("X11/Xlib.h");
});

// Helper function equivalent to #define MAX(a, b) ((a) > (b) ? (a) : (b)) macro in C.
inline fn MAX(a: c_int, b: c_int) c_uint {
    return if (a > b) @intCast(a) else @intCast(b);
}

pub fn main() void {
    var dpy: *x.Display = undefined;
    var root: x.Window = undefined;
    var attr: x.XWindowAttributes = undefined;
    var start: x.XButtonEvent = undefined;
    var ev: x.XEvent = undefined;

    if (x.XOpenDisplay(null)) |display| {
        dpy = display;
        root = x.XDefaultRootWindow(dpy);
    }

    if (dpy == undefined) @panic("Failed to open display");

    _ = x.XGrabKey(dpy, x.XKeysymToKeycode(dpy, x.XStringToKeysym("F1")), x.Mod1Mask, root, 1, x.GrabModeAsync, x.GrabModeAsync);
    _ = x.XGrabButton(dpy, 1, x.Mod1Mask, root, 1, x.ButtonPressMask, x.GrabModeAsync, x.GrabModeAsync, 0, 0);
    _ = x.XGrabButton(dpy, 3, x.Mod1Mask, root, 1, x.ButtonPressMask, x.GrabModeAsync, x.GrabModeAsync, 0, 0);

    while (true) {
        if (x.XNextEvent(dpy, &ev) != 0) continue;

        if (ev.type == x.KeyPress and ev.xkey.subwindow != 0) {
            _ = x.XRaiseWindow(dpy, ev.xkey.subwindow);
        } else if (ev.type == x.ButtonPress and ev.xbutton.subwindow != 0) {
            _ = x.XGrabPointer(dpy, ev.xbutton.subwindow, 1, x.PointerMotionMask | x.ButtonReleaseMask, x.GrabModeAsync, x.GrabModeAsync, 0, 0, x.CurrentTime);
            _ = x.XGetWindowAttributes(dpy, ev.xbutton.subwindow, &attr);
            start = ev.xbutton;
        } else if (ev.type == x.MotionNotify) {
            while (x.XCheckTypedEvent(dpy, x.MotionNotify, &ev) != 0) {}

            const xdiff = ev.xbutton.x_root - start.x_root;
            const ydiff = ev.xbutton.y_root - start.y_root;

            _ = x.XMoveResizeWindow(
                dpy,
                ev.xmotion.window,
                attr.x + (if (start.button == 1) xdiff else 0),
                attr.y + (if (start.button == 1) ydiff else 0),
                MAX(1, attr.width + (if (start.button == 3) xdiff else 0)),
                MAX(1, attr.height + (if (start.button == 3) ydiff else 0)),
            );
        } else if (ev.type == x.ButtonRelease) {
            _ = x.XUngrabPointer(dpy, x.CurrentTime);
        }
    }
}
