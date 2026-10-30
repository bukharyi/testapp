package io.github.bukharyi.stresslive;

import android.content.Context;

import com.garmin.android.connectiq.ConnectIQ;
import com.garmin.android.connectiq.IQApp;
import com.garmin.android.connectiq.IQDevice;
import com.garmin.android.connectiq.exception.InvalidStateException;
import com.garmin.android.connectiq.exception.ServiceUnavailableException;

import java.util.List;

/** Receives stress readings from the Stress Alert watch app through Garmin Connect. */
public final class GarminLink {

    /** Id of garmin/alertapp/manifest.xml, with dashes. */
    public static final String WATCH_APP_ID = "03b5c6fa-3245-4279-b988-36acfa873d43";

    public interface Listener {
        void onStatus(String status);

        void onReading(StressLevel.Reading reading);
    }

    private final Context context;
    private final Listener listener;
    private final IQApp watchApp = new IQApp(WATCH_APP_ID);
    private ConnectIQ connectIQ;
    private boolean ready;

    public GarminLink(Context context, Listener listener) {
        this.context = context.getApplicationContext();
        this.listener = listener;
    }

    public void start() {
        connectIQ = ConnectIQ.getInstance(context, ConnectIQ.IQConnectType.WIRELESS);
        connectIQ.initialize(context, true, new ConnectIQ.ConnectIQListener() {
            @Override
            public void onSdkReady() {
                ready = true;
                listenToWatches();
            }

            @Override
            public void onInitializeError(ConnectIQ.IQSdkErrorStatus status) {
                listener.onStatus(describe(status));
            }

            @Override
            public void onSdkShutDown() {
                ready = false;
            }
        });
    }

    public void stop() {
        if (connectIQ == null) {
            return;
        }
        try {
            connectIQ.unregisterAllForEvents();
            connectIQ.shutdown(context);
        } catch (InvalidStateException ignored) {
            // Already shut down.
        }
        ready = false;
    }

    private void listenToWatches() {
        try {
            List<IQDevice> devices = connectIQ.getKnownDevices();
            if (devices == null || devices.isEmpty()) {
                listener.onStatus("No Garmin watch paired in Garmin Connect.");
                return;
            }
            for (IQDevice device : devices) {
                connectIQ.registerForDeviceEvents(device, (d, status) -> {
                    if (status == IQDevice.IQDeviceStatus.CONNECTED) {
                        listener.onStatus(d.getFriendlyName() + " connected. Open Stress Alert on the watch.");
                    } else {
                        listener.onStatus(d.getFriendlyName() + " is not connected.");
                    }
                });
                connectIQ.registerForAppEvents(device, watchApp, (d, app, message, status) -> {
                    if (status != ConnectIQ.IQMessageStatus.SUCCESS) {
                        return;
                    }
                    StressLevel.Reading reading =
                            StressLevel.parse(message, System.currentTimeMillis() / 1000);
                    if (reading != null) {
                        listener.onReading(reading);
                        listener.onStatus("Live from " + d.getFriendlyName());
                    }
                });
            }
        } catch (InvalidStateException | ServiceUnavailableException e) {
            listener.onStatus("Garmin Connect is not available: " + e.getMessage());
        }
    }

    private static String describe(ConnectIQ.IQSdkErrorStatus status) {
        switch (status) {
            case GCM_NOT_INSTALLED:
                return "Install Garmin Connect from the Play Store first.";
            case GCM_UPGRADE_NEEDED:
                return "Update Garmin Connect from the Play Store.";
            case SERVICE_ERROR:
            default:
                return "Could not connect to Garmin Connect (" + status + ").";
        }
    }
}
