package io.github.bukharyi.stresslive;

import android.app.Activity;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.TextView;

/** One screen: the live stress value in Garmin's stress colours. */
public class MainActivity extends Activity implements GarminLink.Listener {

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable ageTicker = new Runnable() {
        @Override
        public void run() {
            render();
            handler.postDelayed(this, 1000);
        }
    };

    private GarminLink link;
    private StressLevel.Reading latest;
    private View circle;
    private TextView value;
    private TextView category;
    private TextView updated;
    private TextView status;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        circle = findViewById(R.id.circle);
        value = findViewById(R.id.value);
        category = findViewById(R.id.category);
        updated = findViewById(R.id.updated);
        status = findViewById(R.id.status);
        link = new GarminLink(this, this);
        link.start();
        render();
    }

    @Override
    protected void onResume() {
        super.onResume();
        handler.post(ageTicker);
    }

    @Override
    protected void onPause() {
        handler.removeCallbacks(ageTicker);
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        link.stop();
        super.onDestroy();
    }

    @Override
    public void onStatus(String text) {
        runOnUiThread(() -> status.setText(text));
    }

    @Override
    public void onReading(StressLevel.Reading reading) {
        runOnUiThread(() -> {
            latest = reading;
            render();
        });
    }

    private void render() {
        long now = System.currentTimeMillis() / 1000;
        Integer stress = latest == null || latest.isStale(now) ? null : latest.stress;
        ((GradientDrawable) circle.getBackground().mutate())
                .setColor(StressLevel.backgroundColor(stress));
        int text = StressLevel.textColor(stress);
        value.setTextColor(text);
        category.setTextColor(text);
        value.setText(StressLevel.isValid(stress) ? String.valueOf(stress) : "--");
        category.setText(StressLevel.category(stress) + (latest != null && latest.demo ? " · DEMO" : ""));
        if (latest == null) {
            updated.setText("Waiting for the watch…");
        } else {
            long age = Math.max(0, now - latest.time);
            updated.setText(latest.isStale(now)
                    ? "Last reading " + age + " s ago (out of date)"
                    : "Updated " + age + " s ago");
        }
    }
}
