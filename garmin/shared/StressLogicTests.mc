import Toybox.Lang;
import Toybox.Test;

// Unit tests. Run with: monkeyc ... --unit-test, then `monkeydo <prg> <device> /t` (see README).

(:test)
function testCalmAndStressedColours(logger as Test.Logger) as Boolean {
    Test.assertEqual(StressLogic.backgroundColor(0), StressLogic.COLOR_CALM);
    Test.assertEqual(StressLogic.backgroundColor(59), StressLogic.COLOR_CALM);
    Test.assertEqual(StressLogic.backgroundColor(60), StressLogic.COLOR_STRESSED);
    Test.assertEqual(StressLogic.backgroundColor(100), StressLogic.COLOR_STRESSED);
    Test.assertEqual(StressLogic.backgroundColor(null), StressLogic.COLOR_UNKNOWN);
    Test.assertEqual(StressLogic.backgroundColor(-1), StressLogic.COLOR_UNKNOWN);
    Test.assertEqual(StressLogic.backgroundColor(101), StressLogic.COLOR_UNKNOWN);
    return true;
}

(:test)
function testBeepCountPerBand(logger as Test.Logger) as Boolean {
    Test.assertEqual(StressLogic.alertLevel(null), 0);
    Test.assertEqual(StressLogic.alertLevel(59), 0);
    Test.assertEqual(StressLogic.alertLevel(60), 1);
    Test.assertEqual(StressLogic.alertLevel(74), 1);
    Test.assertEqual(StressLogic.alertLevel(75), 2);
    Test.assertEqual(StressLogic.alertLevel(89), 2);
    Test.assertEqual(StressLogic.alertLevel(90), 3);
    Test.assertEqual(StressLogic.alertLevel(100), 3);
    return true;
}

(:test)
function testTrackerBeepsOncePerRise(logger as Test.Logger) as Boolean {
    var t = new StressLogic.AlertTracker();
    Test.assertEqual(t.update(30), 0);
    Test.assertEqual(t.update(62), 1);
    Test.assertEqual(t.update(65), 0);   // still band 1: no repeat
    Test.assertEqual(t.update(80), 2);
    Test.assertEqual(t.update(95), 3);
    Test.assertEqual(t.update(99), 0);
    Test.assertEqual(t.update(null), 0); // missing reading changes nothing
    Test.assertEqual(t.currentLevel(), 3);
    return true;
}

(:test)
function testTrackerHysteresis(logger as Test.Logger) as Boolean {
    var t = new StressLogic.AlertTracker();
    Test.assertEqual(t.update(60), 1);
    Test.assertEqual(t.update(58), 0);   // within 5 points: stays armed
    Test.assertEqual(t.update(61), 0);   // so no second beep
    Test.assertEqual(t.update(54), 0);   // clearly calm: re-arms
    Test.assertEqual(t.currentLevel(), 0);
    Test.assertEqual(t.update(60), 1);
    Test.assertEqual(t.update(96), 3);
    Test.assertEqual(t.update(96), 0);   // high values near 100 must not re-arm
    Test.assertEqual(t.update(68), 0);   // drops two bands: re-arms band 2 and 3
    Test.assertEqual(t.currentLevel(), 1);
    Test.assertEqual(t.update(76), 2);
    return true;
}
