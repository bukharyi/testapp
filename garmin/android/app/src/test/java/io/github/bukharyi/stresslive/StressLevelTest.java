package io.github.bukharyi.stresslive;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.junit.Test;

public class StressLevelTest {

    @Test
    public void coloursFollowGarminBands() {
        assertEquals(StressLevel.COLOR_REST, StressLevel.backgroundColor(0));
        assertEquals(StressLevel.COLOR_REST, StressLevel.backgroundColor(25));
        assertEquals(StressLevel.COLOR_LOW, StressLevel.backgroundColor(26));
        assertEquals(StressLevel.COLOR_LOW, StressLevel.backgroundColor(50));
        assertEquals(StressLevel.COLOR_MEDIUM, StressLevel.backgroundColor(51));
        assertEquals(StressLevel.COLOR_MEDIUM, StressLevel.backgroundColor(75));
        assertEquals(StressLevel.COLOR_HIGH, StressLevel.backgroundColor(76));
        assertEquals(StressLevel.COLOR_HIGH, StressLevel.backgroundColor(100));
        assertEquals(StressLevel.COLOR_UNKNOWN, StressLevel.backgroundColor(null));
        assertEquals(StressLevel.COLOR_UNKNOWN, StressLevel.backgroundColor(-1));
        assertEquals(StressLevel.COLOR_UNKNOWN, StressLevel.backgroundColor(101));
    }

    @Test
    public void categoriesAndTextColour() {
        assertEquals("REST", StressLevel.category(10));
        assertEquals("LOW", StressLevel.category(40));
        assertEquals("MEDIUM", StressLevel.category(60));
        assertEquals("HIGH", StressLevel.category(90));
        assertEquals("NO DATA", StressLevel.category(null));
        assertEquals(0xFF000000, StressLevel.textColor(40));
        assertEquals(0xFFFFFFFF, StressLevel.textColor(90));
    }

    @Test
    public void parsesWatchMessage() {
        // Connect IQ delivers a Monkey C dictionary as a HashMap with Integer/Boolean values.
        Map<Object, Object> map = new HashMap<>();
        map.put("stress", 72);
        map.put("demo", true);
        map.put("time", 1_800_000_000);
        StressLevel.Reading r = StressLevel.parse(Collections.singletonList(map), 5);
        assertEquals(Integer.valueOf(72), r.stress);
        assertTrue(r.demo);
        assertEquals(1_800_000_000L, r.time);
    }

    @Test
    public void noReadingFromWatchBecomesNull() {
        Map<Object, Object> map = new HashMap<>();
        map.put("stress", -1);
        StressLevel.Reading r = StressLevel.parse(Collections.singletonList(map), 123);
        assertNull(r.stress);
        assertFalse(r.demo);
        assertEquals(123L, r.time);
    }

    @Test
    public void ignoresUnexpectedMessages() {
        assertNull(StressLevel.parse(null, 0));
        assertNull(StressLevel.parse(Collections.emptyList(), 0));
        List<Object> junk = Arrays.asList("hello", 42, new HashMap<>());
        assertNull(StressLevel.parse(junk, 0));
    }

    @Test
    public void readingGoesStaleAfter30Seconds() {
        StressLevel.Reading r = new StressLevel.Reading(50, false, 1000);
        assertFalse(r.isStale(1030));
        assertTrue(r.isStale(1031));
    }
}
