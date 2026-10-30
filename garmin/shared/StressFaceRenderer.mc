import Toybox.Lang;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Draws the face. The watch face and the alert app both call this, so they look identical.
module StressFaceRenderer {

    // lowPower: AMOLED always-on mode, where filling the screen is not allowed.
    // That mode keeps a black background and shows the stress colour in the text instead.
    function draw(dc as Graphics.Dc, stress as Number?, lowPower as Boolean, tag as String?) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var colour = StressLogic.backgroundColor(stress);
        var bg = lowPower ? Graphics.COLOR_BLACK : colour;
        var fg = StressLogic.textColor(stress);
        if (lowPower && StressLogic.isValid(stress)) {
            fg = colour;
        }

        dc.setColor(bg, bg);
        dc.clear();
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);

        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        dc.drawText(cx, h * 0.14, Graphics.FONT_XTINY,
            Lang.format("$1$ $2$ $3$", [info.day_of_week, info.day, info.month]).toUpper(),
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(cx, h * 0.40, Graphics.FONT_NUMBER_THAI_HOT, timeString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var value = StressLogic.isValid(stress) ? (stress as Number).toString() : "--";
        dc.drawText(cx, h * 0.62, Graphics.FONT_MEDIUM, "STRESS " + value,
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h * 0.76, Graphics.FONT_XTINY, StressLogic.statusText(stress),
            Graphics.TEXT_JUSTIFY_CENTER);

        if (tag != null) {
            dc.drawText(cx, h * 0.86, Graphics.FONT_XTINY, tag, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function timeString() as String {
        var clock = System.getClockTime();
        var hour = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        return Lang.format("$1$:$2$", [hour.format("%02d"), clock.min.format("%02d")]);
    }
}
