import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;
import Toybox.Time;
import Toybox.Timer;
import Toybox.Lang;

(:glance)
class TimeLoggerGlance extends WatchUi.GlanceView {

    var refreshTimer;

    function initialize() {
        GlanceView.initialize();
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
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var h = dc.getHeight();
        var leftPad = 4;
        var leftJust = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        var category = Application.Storage.getValue("currentCategory");
        if (category != null) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftPad, h / 2 - 14, Graphics.FONT_GLANCE, "● " + category, leftJust);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftPad, h / 2 + 14, Graphics.FONT_GLANCE_NUMBER, computeElapsed(), leftJust);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftPad, h / 2, Graphics.FONT_GLANCE, "TimeLogger", leftJust);
        }
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
