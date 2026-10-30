import Toybox.Communications;
import Toybox.Lang;
import Toybox.Time;

// Sends stress readings to the Stress Live Android app (garmin/android) over Bluetooth,
// through Garmin Connect on the phone. The message is a dictionary:
//   {"stress" => 0-100 or -1 for no reading, "demo" => Boolean, "time" => Unix seconds}
class PhoneLink extends Communications.ConnectionListener {

    // Resend an unchanged value this often, so the phone knows the watch is still there.
    private const HEARTBEAT_S = 10;

    private var _busy as Boolean = false;
    private var _lastSent as Number? = null;
    private var _lastSentAt as Number = 0;

    function initialize() {
        ConnectionListener.initialize();
    }

    function send(stress as Number?, demo as Boolean) as Void {
        var value = StressLogic.isValid(stress) ? stress as Number : -1;
        var now = Time.now().value();
        if (_busy || (value == _lastSent && now - _lastSentAt < HEARTBEAT_S)) {
            return;
        }
        _busy = true;
        _lastSent = value;
        _lastSentAt = now;
        Communications.transmit({"stress" => value, "demo" => demo, "time" => now}, null, self);
    }

    function onComplete() as Void {
        _busy = false;
    }

    // Phone out of range or app not installed: try again on the next reading.
    function onError() as Void {
        _busy = false;
        _lastSent = null;
    }
}
