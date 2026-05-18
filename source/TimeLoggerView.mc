import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;
import Toybox.Time;
import Toybox.Timer;
import Toybox.Lang;

class TimeLoggerView extends WatchUi.View {

    var refreshTimer;

    function initialize() {
        View.initialize();
    }

    function onShow() {
        refreshTimer = new Timer.Timer();
        refreshTimer.start(method(:onTick), 1000, true);
    }

    function onHide() {
        if (refreshTimer != null) {
            refreshTimer.stop();
            refreshTimer = null;
        }
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
        if (Application.Storage.getValue("pendingCheckin") == true) {
            var cat = Application.Storage.getValue("currentCategory");
            if (cat != null) {
                // Clear flag at push so we don't re-push on the next tick.
                // ConfirmationDelegate handles Yes/No; Yes is a no-op,
                // No calls stopTogglTimer (which also cancels the next checkin).
                Application.Storage.deleteValue("pendingCheckin");
                var conf = new WatchUi.Confirmation("Still doing " + cat + "?");
                WatchUi.pushView(conf, new TimeLoggerCheckinConfirmationDelegate(), WatchUi.SLIDE_UP);
            }
            // If cat is null (sync in flight), leave the flag for next tick.
        }
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        var currentCategory = Application.Storage.getValue("currentCategory");
        if (currentCategory != null) {
            drawRunning(dc, cx, cy, currentCategory);
        } else {
            drawIdle(dc, cx, cy);
        }
    }

    function drawIdle(dc, cx, cy) {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 20, Graphics.FONT_LARGE, "TimeLogger", center);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 30, Graphics.FONT_TINY, "press START", center);
    }

    function drawRunning(dc, cx, cy, category) {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        // Status label at top
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 95, Graphics.FONT_TINY, "● RUNNING", center);

        // Category name
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 55, Graphics.FONT_MEDIUM, category, center);

        // Elapsed time (the focal point)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 5, Graphics.FONT_NUMBER_MILD, computeElapsed(), center);

        // Bottom hints, two lines
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 70, Graphics.FONT_XTINY, "START to stop / switch", center);
        dc.drawText(cx, cy + 95, Graphics.FONT_XTINY, "BACK to exit", center);
    }

    function computeElapsed() {
        var startEpoch = Application.Storage.getValue("currentStartEpoch");
        if (startEpoch == null) {
            return "0:00";
        }
        var elapsed = Time.now().value() - startEpoch;
        if (elapsed < 0) {
            elapsed = 0;
        }
        var hours = elapsed / 3600;
        var mins = (elapsed % 3600) / 60;
        var secs = elapsed % 60;
        if (hours > 0) {
            return Lang.format("$1$:$2$:$3$", [hours, mins.format("%02d"), secs.format("%02d")]);
        }
        return Lang.format("$1$:$2$", [mins, secs.format("%02d")]);
    }
}
