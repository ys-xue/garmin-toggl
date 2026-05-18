import Toybox.Background;
import Toybox.System;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Time;
import Toybox.Lang;

// Runs in a separate background process. Woken by the system 15 min after
// each scheduled temporal event. Vibrates, sets a flag for the foreground
// to surface a "Still doing X?" prompt, then re-arms itself.
(:background)
class TimeLoggerCheckinService extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        var entryId = Application.Storage.getValue("currentEntryId");
        if (entryId == null) {
            // No timer running — don't re-arm.
            Background.exit(null);
            return;
        }

        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(75, 1500)] as Lang.Array<Attention.VibeProfile>);
        }

        Application.Storage.setValue("pendingCheckin", true);

        // Re-arm for the next 15-minute interval.
        Background.registerForTemporalEvent(new Time.Moment(Time.now().value() + 15 * 60));

        Background.exit(null);
    }
}
