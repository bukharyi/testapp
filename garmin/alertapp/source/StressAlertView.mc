import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Same face as the watch face, plus 1/2/3 beeps and vibrations when stress climbs.
// Press START to run a demo that ramps stress up and down.
// Every reading is also sent to the Stress Live phone app.
class StressAlertView extends WatchUi.View {

    // Demo ramp: calm -> each alert band -> back to calm. One step every DEMO_STEP_MS.
    private const DEMO_STEPS = [25, 45, 58, 62, 68, 77, 84, 93, 98, 80, 55, 30] as Array<Number>;
    private const DEMO_STEP_MS = 3000;
    private const REFRESH_MS = 1000;

    private var _timer as Timer.Timer;
    private var _tracker as StressLogic.AlertTracker;
    private var _demo as Boolean = false;
    private var _demoIndex as Number = 0;
    private var _demoElapsed as Number = 0;
    private var _stress as Number? = null;
    private var _phone as PhoneLink;

    function initialize() {
        View.initialize();
        _timer = new Timer.Timer();
        _tracker = new StressLogic.AlertTracker();
        _phone = new PhoneLink();
    }

    function onShow() as Void {
        _timer.start(method(:onTick), REFRESH_MS, true);
        onTick();
    }

    function onHide() as Void {
        _timer.stop();
    }

    function onTick() as Void {
        if (_demo) {
            _demoElapsed += REFRESH_MS;
            if (_demoElapsed >= DEMO_STEP_MS) {
                _demoElapsed = 0;
                _demoIndex = (_demoIndex + 1) % DEMO_STEPS.size();
            }
            _stress = DEMO_STEPS[_demoIndex];
        } else {
            _stress = StressLogic.readStress();
        }
        var beeps = _tracker.update(_stress);
        if (beeps > 0) {
            StressAlerter.alert(beeps);
        }
        _phone.send(_stress, _demo);
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        StressFaceRenderer.draw(dc, _stress, false, _demo ? "DEMO" : null);
    }

    function toggleDemo() as Void {
        _demo = !_demo;
        _demoIndex = 0;
        _demoElapsed = 0;
        _tracker.reset();
        onTick();
    }
}

class StressAlertDelegate extends WatchUi.BehaviorDelegate {

    private var _view as StressAlertView;

    function initialize(view as StressAlertView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        _view.toggleDemo();
        return true;
    }
}
