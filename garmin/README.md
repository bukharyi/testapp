# Stress Face for Garmin Forerunner

A digital watch face that shows your current Garmin stress level and colours the whole screen
with the same accent colours as Garmin's stress widget:

| Stress | Screen | Garmin category |
|---|---|---|
| 0-25 | **Blue** | Rest |
| 26-50 | **Amber** (black text) | Low |
| 51-75 | **Orange** | Medium |
| 76-100 | **Dark red-orange** | High |
| no reading (off wrist, running, etc.) | Black, `NO DATA` | none |

The Stress Alert app also beeps and vibrates at the same time:

| Stress | Alert |
|---|---|
| 60-74 | 1 beep + 1 vibration |
| 75-89 | 2 beeps + 2 vibrations |
| 90-100 | 3 beeps + 3 vibrations |

The colours are snapped to the 64-colour palette of the Forerunner 945's screen, so they are
close to the widget's shades but not exact on AMOLED watches.

Alerts fire once each time stress climbs into a higher band, not every minute. A band can alert
again only after stress has dropped at least 5 points below it, so a reading that wobbles around
60 does not keep beeping. Thresholds and colours are constants at the top of
`shared/StressLogic.mc`.

## Why there are two apps

Garmin does not allow **watch faces** to beep or vibrate: the `Attention` API is off-limits to
them. So the project has two parts:

- `watchface/`: **Stress Face**, the always-on watch face (colours only).
- `alertapp/`: **Stress Alert**, a watch app with the same screen that also beeps and vibrates 1, 2
  or 3 times. Start it from the app list when you want audible alerts. Press **START** inside it
  to run a demo that ramps stress 25 → 98 → 30 so you can see and feel every level.

Tip: for an alert while the watch face is showing, also turn on Garmin's own
*Settings → Health & Wellness → Stress → Relax Reminders*. It vibrates when stress is high.

Both apps share `shared/` (the logic, the drawing and the unit tests).

## Supported watches

`fr945`, `fr945lte`, `fr955`, `fr965`, `fr970`. There is no "Forerunner 975". If your watch is
another model, add its id to both `manifest.xml` files. On AMOLED watches (965/970) the
always-on mode keeps a black background and colours the text, because Garmin turns the screen off
if a watch face lights the whole display in that mode.

## Build and install (needs the free Garmin Connect IQ SDK)

1. Install the [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/), sign in,
   download the latest SDK and your watch's device files.
2. Create a developer key once, inside the `garmin/` folder:
   ```sh
   openssl genrsa -out developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
   ```
3. Build (replace `fr965` with your watch id):
   ```sh
   cd garmin/watchface && monkeyc -d fr965 -f monkey.jungle -o StressFace.prg -y ../developer_key.der
   cd ../alertapp      && monkeyc -d fr965 -f monkey.jungle -o StressAlert.prg -y ../developer_key.der
   ```
   In VS Code with the Monkey C extension you can instead open `watchface/` or `alertapp/` and
   run *Monkey C: Build for Device*.
4. Plug the watch in by USB and copy both `.prg` files into `GARMIN/APPS/` on the watch. Macs
   need [OpenMTP](https://openmtp.ganeshrvel.com/) for the 955/965/970. Unplug it.
5. On the watch, long-press **UP** → *Watch Face* → pick **Stress Face**. **Stress Alert** is in
   the apps list (**START** button).

Make sure *Settings → System → Sound & Vibration* has tones and vibration on, or you will feel
the vibrations but hear no beeps.

## Testing

**On Garmin's simulator (real Monkey C):**
```sh
cd garmin/alertapp
monkeyc -d fr965 -f monkey.jungle -o test.prg -y ../developer_key.der --unit-test
connectiq &                 # start the simulator
monkeydo test.prg fr965 /t  # runs the 4 tests in shared/StressLogicTests.mc
```
To simulate stress, run `StressAlert.prg` in the simulator and press START (demo mode). Or use
*Simulation → Activity Monitor / Sensor History* to set a stress value.

**Without the SDK (Python):**
```sh
python3 garmin/sim/simulate.py       # runs a stress scenario, writes sim/output/stress_simulation.png
cd garmin/sim && python3 run_mc_tests.py  # runs the same assertions as the Monkey C tests
```
These check a Python copy of `StressLogic.mc` and read its thresholds from the `.mc` file.
They do not compile or run the Monkey C code.
