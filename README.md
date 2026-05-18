# TimeLogger

A Garmin Connect IQ watch app for logging time entries straight to [Toggl Track](https://toggl.com/track/). Pick a category from a menu, press START, the timer runs on Toggl's side and the watch shows the elapsed time. Press BACK to stop.

Target: Forerunner 570 (47mm). Should work on other CIQ 6+ devices with minor manifest tweaks.

## Features

- Idle screen shows app name; running screen shows category, elapsed timer (live), and key hints
- START opens a category menu; picking another category atomically switches the running Toggl entry
- BACK on the running screen stops the timer immediately
- Categories configurable via Garmin Connect app settings (comma-separated string)
- All timestamps sent to Toggl in UTC

## Setup

1. **Toggl credentials**

   - Get your API token from <https://track.toggl.com/profile> (bottom of page).
   - Get your workspace ID from any Toggl URL or workspace settings.
   - Compute the basic auth header:

     ```bash
     echo -n "YOUR_TOKEN:api_token" | base64
     ```

   - Copy `Secrets.mc.example` to `source/Secrets.mc` and fill in the three constants. `source/Secrets.mc` is gitignored.

2. **Garmin SDK**

   Install the Connect IQ SDK and a developer key. The build command below assumes both exist.

3. **Build**

   For the simulator (debug):

   ```bash
   java -jar "$CIQ_SDK/bin/monkeybrains.jar" \
     -o bin/TimeLogger.prg \
     -f monkey.jungle \
     -y /path/to/developer_key \
     -d fr57047mm_sim -w
   ```

   For the watch (release):

   ```bash
   java -jar "$CIQ_SDK/bin/monkeybrains.jar" \
     -o bin/TimeLogger.prg \
     -f monkey.jungle \
     -y /path/to/developer_key \
     -d fr57047mm -r -w
   ```

4. **Install on watch**

   Connect the watch via USB and copy `bin/TimeLogger.prg` to `GARMIN/APPS/`. Launch from Start → Apps → TimeLogger.

## Notes

- App type is `watch-app`; older `widget` type isn't supported on FR570.
- Categories default to `Deep Work, Meeting, Commute, Workout, Life Ops, Spanish, Reading, Personal`. Change them in Garmin Connect Mobile → device → app settings.
- Toggl's v9 API treats `duration: -1` as a running timer. Starting a new entry auto-stops any other running entry on the account.
