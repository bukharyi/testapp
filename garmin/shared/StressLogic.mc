import Toybox.Lang;
import Toybox.ActivityMonitor;
import Toybox.SensorHistory;

// Shared by the watch face and the alert app, so both make the same decisions.
module StressLogic {

    // Stress at or above this value counts as "stressed" (red).
    const STRESS_THRESHOLD = 60;
    // 60-74 -> 1 beep, 75-89 -> 2 beeps, 90-100 -> 3 beeps.
    const LEVEL2_THRESHOLD = 75;
    const LEVEL3_THRESHOLD = 90;
    // Stress has to fall this many points below a band before that band can alert again,
    // so a reading that wobbles between 59 and 60 does not beep every few minutes.
    const HYSTERESIS = 5;

    // Palette-safe colours, so they look the same on 64-colour MIP and AMOLED screens.
    // Blue is Garmin's "rest" colour; red is used for stress, as requested.
    const COLOR_CALM = 0x00AAFF;
    const COLOR_STRESSED = 0xFF0000;
    const COLOR_UNKNOWN = 0x000000;

    function isValid(stress as Number?) as Boolean {
        return stress != null && stress >= 0 && stress <= 100;
    }

    function isStressed(stress as Number?) as Boolean {
        return isValid(stress) && (stress as Number) >= STRESS_THRESHOLD;
    }

    // 0 = no alert, otherwise the number of beeps / vibrations (1-3).
    function alertLevel(stress as Number?) as Number {
        if (!isStressed(stress)) {
            return 0;
        }
        var s = stress as Number;
        if (s >= LEVEL3_THRESHOLD) {
            return 3;
        }
        if (s >= LEVEL2_THRESHOLD) {
            return 2;
        }
        return 1;
    }

    function backgroundColor(stress as Number?) as Number {
        if (!isValid(stress)) {
            return COLOR_UNKNOWN;
        }
        return isStressed(stress) ? COLOR_STRESSED : COLOR_CALM;
    }

    function statusText(stress as Number?) as String {
        if (!isValid(stress)) {
            return "NO DATA";
        }
        return isStressed(stress) ? "STRESSED" : "CALM";
    }

    // Latest stress value 0-100, or null when the watch has none (e.g. off wrist or moving).
    function readStress() as Number? {
        if (ActivityMonitor.Info has :stressScore) {
            var score = ActivityMonitor.getInfo().stressScore;
            if (score != null && isValid(score.toNumber())) {
                return score.toNumber();
            }
        }
        if ((Toybox has :SensorHistory) && (SensorHistory has :getStressHistory)) {
            var history = SensorHistory.getStressHistory({
                :period => 1,
                :order => SensorHistory.ORDER_NEWEST_FIRST
            });
            if (history != null) {
                var sample = history.next();
                if (sample != null && sample.data != null) {
                    var value = (sample.data as Numeric).toNumber();
                    if (isValid(value)) {
                        return value;
                    }
                }
            }
        }
        return null;
    }

    // Decides when to beep: once each time stress climbs into a higher band.
    class AlertTracker {
        private var _armedLevel as Number = 0;

        function initialize() {
        }

        // Feed every new reading. Returns how many beeps to play now (0 = stay quiet).
        function update(stress as Number?) as Number {
            if (!isValid(stress)) {
                return 0;
            }
            var level = alertLevel(stress);
            if (level > _armedLevel) {
                _armedLevel = level;
                return level;
            }
            var padded = (stress as Number) + HYSTERESIS;
            var relaxed = alertLevel(padded > 100 ? 100 : padded);
            if (relaxed < _armedLevel) {
                _armedLevel = relaxed;
            }
            return 0;
        }

        function currentLevel() as Number {
            return _armedLevel;
        }

        function reset() as Void {
            _armedLevel = 0;
        }
    }
}
