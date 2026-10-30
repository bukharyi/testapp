import Toybox.Attention;
import Toybox.Lang;

module StressAlerter {

    const PULSE_MS = 250;
    const GAP_MS = 200;
    const TONE_HZ = 2500;

    // Beeps and vibrates `count` times at once. Tones follow the watch's sound setting:
    // if sounds are off on the watch, only the vibration is felt.
    function alert(count as Number) as Void {
        if (Attention has :vibrate) {
            var vibes = [] as Array<Attention.VibeProfile>;
            for (var i = 0; i < count; i++) {
                if (i > 0) {
                    vibes.add(new Attention.VibeProfile(0, GAP_MS));
                }
                vibes.add(new Attention.VibeProfile(100, PULSE_MS));
            }
            Attention.vibrate(vibes);
        }
        if (Attention has :playTone) {
            if (Attention has :ToneProfile) {
                var tones = [] as Array<Attention.ToneProfile>;
                for (var i = 0; i < count; i++) {
                    if (i > 0) {
                        tones.add(new Attention.ToneProfile(0, GAP_MS));
                    }
                    tones.add(new Attention.ToneProfile(TONE_HZ, PULSE_MS));
                }
                Attention.playTone({:toneProfile => tones});
            } else {
                Attention.playTone(Attention.TONE_ALERT_HI);
            }
        }
    }
}
