package io.github.bukharyi.stresslive;

import java.util.List;
import java.util.Map;

/** Stress categories and colours. Matches garmin/shared/StressLogic.mc on the watch. */
public final class StressLevel {

    public static final int REST_MAX = 25;
    public static final int LOW_MAX = 50;
    public static final int MEDIUM_MAX = 75;

    // Same colours as the watch face (ARGB).
    public static final int COLOR_REST = 0xFF00AAFF;
    public static final int COLOR_LOW = 0xFFFFAA00;
    public static final int COLOR_MEDIUM = 0xFFFF5500;
    public static final int COLOR_HIGH = 0xFFAA0000;
    public static final int COLOR_UNKNOWN = 0xFF000000;

    /** A reading older than this is shown as out of date. */
    public static final long STALE_AFTER_S = 30;

    private StressLevel() {
    }

    public static boolean isValid(Integer stress) {
        return stress != null && stress >= 0 && stress <= 100;
    }

    public static int backgroundColor(Integer stress) {
        if (!isValid(stress)) {
            return COLOR_UNKNOWN;
        }
        if (stress <= REST_MAX) {
            return COLOR_REST;
        }
        if (stress <= LOW_MAX) {
            return COLOR_LOW;
        }
        if (stress <= MEDIUM_MAX) {
            return COLOR_MEDIUM;
        }
        return COLOR_HIGH;
    }

    /** White text is hard to read on amber, so that band uses black. */
    public static int textColor(Integer stress) {
        if (!isValid(stress)) {
            return 0xFFAAAAAA;
        }
        return backgroundColor(stress) == COLOR_LOW ? 0xFF000000 : 0xFFFFFFFF;
    }

    public static String category(Integer stress) {
        if (!isValid(stress)) {
            return "NO DATA";
        }
        if (stress <= REST_MAX) {
            return "REST";
        }
        if (stress <= LOW_MAX) {
            return "LOW";
        }
        if (stress <= MEDIUM_MAX) {
            return "MEDIUM";
        }
        return "HIGH";
    }

    /** One message from the watch: {"stress": 0-100 or -1, "demo": bool, "time": unix seconds}. */
    public static final class Reading {
        public final Integer stress;
        public final boolean demo;
        public final long time;

        public Reading(Integer stress, boolean demo, long time) {
            this.stress = stress;
            this.demo = demo;
            this.time = time;
        }

        public boolean isStale(long nowSeconds) {
            return nowSeconds - time > STALE_AFTER_S;
        }
    }

    /**
     * Turns a Connect IQ message into a Reading. Returns null for anything that does not look
     * like one. receivedAt (unix seconds) is used when the watch did not send a time.
     */
    public static Reading parse(List<Object> message, long receivedAt) {
        if (message == null) {
            return null;
        }
        for (Object item : message) {
            if (!(item instanceof Map)) {
                continue;
            }
            Map<?, ?> map = (Map<?, ?>) item;
            Object stress = map.get("stress");
            if (!(stress instanceof Number)) {
                continue;
            }
            int value = ((Number) stress).intValue();
            Object demo = map.get("demo");
            Object time = map.get("time");
            return new Reading(
                    isValid(value) ? value : null,
                    Boolean.TRUE.equals(demo),
                    time instanceof Number ? ((Number) time).longValue() : receivedAt);
        }
        return null;
    }
}
