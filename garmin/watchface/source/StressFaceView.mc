import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Garmin does not let watch faces beep or vibrate, so this view only shows colours.
// The "Stress Alert" app in ../alertapp does the beeping.
class StressFaceView extends WatchUi.WatchFace {

    private var _lowPower as Boolean = false;
    private var _burnInProtection as Boolean = false;

    function initialize() {
        WatchFace.initialize();
        var settings = System.getDeviceSettings();
        if (settings has :requiresBurnInProtection) {
            _burnInProtection = settings.requiresBurnInProtection;
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        StressFaceRenderer.draw(dc, StressLogic.readStress(), _lowPower && _burnInProtection, null);
    }

    function onEnterSleep() as Void {
        _lowPower = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _lowPower = false;
        WatchUi.requestUpdate();
    }
}
