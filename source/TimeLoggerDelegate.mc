import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Communications;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;
import Toybox.Application;
import Toybox.Background;

class TimeLoggerDelegate extends WatchUi.BehaviorDelegate {

    // Toggl credentials live in source/Secrets.mc (gitignored).
    var workspaceId = Secrets.WORKSPACE_ID;
    var authHeader  = Secrets.AUTH_HEADER;

    function initialize() {
        BehaviorDelegate.initialize();
        syncRunningEntryFromToggl();
    }

    function onSelect() {
        // If a timer is already running, stop it first then push the menu —
        // one-button switch: START → stop → pick next (or BACK to just stop).
        if (Application.Storage.getValue("currentEntryId") != null) {
            stopTogglTimer();
        }

        var menu = new WatchUi.Menu2({:title=>"Log Activity"});
        var buckets = Categories.BUCKETS;
        for (var i = 0; i < buckets.size(); i++) {
            var b = buckets[i];
            var label = b[:name];
            if (b[:subs].size() > 0) {
                label = label + " ›";
            }
            menu.addItem(new WatchUi.MenuItem(label, null, i, null));
        }
        WatchUi.pushView(menu, new TimeLoggerMainMenuDelegate(self), WatchUi.SLIDE_UP);
        return true;
    }

    // BACK is not overridden, so it exits the app via the default behavior.
    // A running timer keeps running on Toggl; the next app launch adopts it
    // back via syncRunningEntryFromToggl below. This also covers entries
    // started or stopped from another Toggl client.
    function syncRunningEntryFromToggl() {
        var url = "https://api.track.toggl.com/api/v9/me/time_entries/current";
        var headers = {
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
            "Authorization" => authHeader
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => headers,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(url, null, options, method(:onSyncReceive));
    }

    function onSyncReceive(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        // Toggl returns literal `null` (HTTP 200) when no timer is running,
        // which Garmin's JSON parser rejects with -400 INVALID_HTTP_BODY.
        // Treat that as "nothing running" instead of a real error.
        var nothingRunning = (responseCode == -400)
            || (responseCode == 200 && (!(data instanceof Lang.Dictionary) || !data.hasKey("id")));

        if (nothingRunning) {
            Application.Storage.deleteValue("currentEntryId");
            Application.Storage.deleteValue("currentCategory");
            Application.Storage.deleteValue("currentStartEpoch");
            Application.Storage.deleteValue("currentStartIso");
            Application.Storage.deleteValue("currentProjectId");
            cancelCheckin();
            WatchUi.requestUpdate();
            return;
        }
        if (responseCode != 200) {
            System.println("Toggl sync error: " + responseCode);
            return;
        }
        // Adopt the running entry. For running entries Toggl stores
        // duration as -(unix_start_timestamp), so start_epoch = -duration.
        Application.Storage.setValue("currentEntryId", data["id"]);
        Application.Storage.setValue("currentCategory", data["description"]);
        var dur = data["duration"];
        if (dur != null && dur < 0) {
            Application.Storage.setValue("currentStartEpoch", -dur);
        }
        if (data.hasKey("start")) {
            Application.Storage.setValue("currentStartIso", data["start"]);
        }
        if (data.hasKey("project_id")) {
            Application.Storage.setValue("currentProjectId", data["project_id"]);
        }
        // Ensure a checkin is armed for the adopted entry (idempotent — replaces any existing schedule).
        scheduleCheckin();
        WatchUi.requestUpdate();
    }

    function pushSubMenu(bucketIdx) {
        var b = Categories.BUCKETS[bucketIdx];
        var submenu = new WatchUi.Menu2({:title => b[:name]});
        submenu.addItem(new WatchUi.MenuItem("Just " + b[:name], null, b[:name], null));
        var subs = b[:subs];
        for (var i = 0; i < subs.size(); i++) {
            submenu.addItem(new WatchUi.MenuItem(subs[i], null, subs[i], null));
        }
        WatchUi.pushView(submenu, new TimeLoggerSubMenuDelegate(self, b[:projectId]), WatchUi.SLIDE_LEFT);
    }

    function startTogglTimer(category, projectId) {
        var nowMoment = Time.now();
        var startIso = isoFromMoment(nowMoment);

        var url = "https://api.track.toggl.com/api/v9/workspaces/" + workspaceId + "/time_entries";

        var headers = {
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
            "Authorization" => authHeader
        };

        var params = {
            "description" => category,
            "created_with" => "GarminForerunner570",
            "start" => startIso,
            "duration" => -1,
            "workspace_id" => workspaceId.toNumber()
        };
        if (projectId != null) {
            params["project_id"] = projectId;
        }

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => headers,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Application.Storage.setValue("pendingCategory", category);
        Application.Storage.setValue("pendingStartEpoch", nowMoment.value());
        Application.Storage.setValue("pendingStartIso", startIso);
        Application.Storage.setValue("pendingProjectId", projectId);

        WatchUi.showToast("Starting...", {:duration => 1000});
        Communications.makeWebRequest(url, params, options, method(:onStartReceive));
    }

    function onStartReceive(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        if (responseCode == 201 || responseCode == 200) {
            if (data instanceof Lang.Dictionary && data.hasKey("id")) {
                Application.Storage.setValue("currentEntryId", data["id"]);
                Application.Storage.setValue("currentCategory", Application.Storage.getValue("pendingCategory"));
                Application.Storage.setValue("currentStartEpoch", Application.Storage.getValue("pendingStartEpoch"));
                Application.Storage.setValue("currentStartIso", Application.Storage.getValue("pendingStartIso"));
                Application.Storage.setValue("currentProjectId", Application.Storage.getValue("pendingProjectId"));
            }
            scheduleCheckin();
            WatchUi.showToast("Started", {:duration => 2000});
        } else {
            System.println("Toggl start error: " + responseCode);
            WatchUi.showToast("Err: " + responseCode, {:duration => 3000});
        }
        Application.Storage.deleteValue("pendingCategory");
        Application.Storage.deleteValue("pendingStartEpoch");
        Application.Storage.deleteValue("pendingStartIso");
        Application.Storage.deleteValue("pendingProjectId");
    }

    function stopTogglTimer() {
        var entryId = Application.Storage.getValue("currentEntryId");
        var startEpoch = Application.Storage.getValue("currentStartEpoch");
        var startIso = Application.Storage.getValue("currentStartIso");
        var category = Application.Storage.getValue("currentCategory");
        var projectId = Application.Storage.getValue("currentProjectId");

        if (entryId == null || startEpoch == null) {
            WatchUi.showToast("Nothing running", {:duration => 2000});
            Application.Storage.deleteValue("currentEntryId");
            Application.Storage.deleteValue("currentCategory");
            Application.Storage.deleteValue("currentStartEpoch");
            Application.Storage.deleteValue("currentStartIso");
            Application.Storage.deleteValue("currentProjectId");
            return;
        }

        // Clear local state up front: view flips to idle, prevents double-stop.
        Application.Storage.deleteValue("currentEntryId");
        Application.Storage.deleteValue("currentCategory");
        Application.Storage.deleteValue("currentStartEpoch");
        Application.Storage.deleteValue("currentStartIso");
        Application.Storage.deleteValue("currentProjectId");
        cancelCheckin();
        WatchUi.requestUpdate();

        var nowMoment = Time.now();
        var stopIso = isoFromMoment(nowMoment);
        var duration = nowMoment.value() - startEpoch;

        var url = "https://api.track.toggl.com/api/v9/workspaces/" + workspaceId
                  + "/time_entries/" + entryId;

        var headers = {
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
            "Authorization" => authHeader
        };

        var params = {
            "description" => category,
            "created_with" => "GarminForerunner570",
            "start" => startIso,
            "stop" => stopIso,
            "duration" => duration,
            "workspace_id" => workspaceId.toNumber()
        };
        if (projectId != null) {
            params["project_id"] = projectId;
        }

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_PUT,
            :headers => headers,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        WatchUi.showToast("Stopping...", {:duration => 1000});
        Communications.makeWebRequest(url, params, options, method(:onStopReceive));
    }

    function onStopReceive(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        if (responseCode == 200 || responseCode == 404 || responseCode == 409) {
            WatchUi.showToast("Stopped", {:duration => 2000});
        } else {
            System.println("Toggl stop error: " + responseCode);
            WatchUi.showToast("Err: " + responseCode, {:duration => 3000});
        }
    }

    function scheduleCheckin() {
        try {
            Background.registerForTemporalEvent(new Time.Moment(Time.now().value() + 15 * 60));
        } catch (e) {
            System.println("Checkin schedule error: " + e.getErrorMessage());
        }
    }

    function cancelCheckin() {
        try {
            Background.deleteTemporalEvent();
        } catch (e) {
            // No event scheduled — fine.
        }
        Application.Storage.deleteValue("pendingCheckin");
    }

    function isoFromMoment(moment) {
        var date = Gregorian.utcInfo(moment, Time.FORMAT_SHORT);
        return Lang.format("$1$-$2$-$3$T$4$:$5$:$6$Z", [
            date.year,
            date.month.format("%02d"),
            date.day.format("%02d"),
            date.hour.format("%02d"),
            date.min.format("%02d"),
            date.sec.format("%02d")
        ]);
    }
}

class TimeLoggerMainMenuDelegate extends WatchUi.Menu2InputDelegate {
    var parent;
    function initialize(p) {
        Menu2InputDelegate.initialize();
        parent = p;
    }
    function onSelect(item) {
        var idx = item.getId() as Lang.Number;
        var b = Categories.BUCKETS[idx];
        if (b[:subs].size() == 0) {
            parent.startTogglTimer(b[:name], b[:projectId]);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            parent.pushSubMenu(idx);
        }
    }
}

class TimeLoggerCheckinConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        ConfirmationDelegate.initialize();
    }
    function onResponse(response) {
        if (response == WatchUi.CONFIRM_NO) {
            var app = Application.getApp() as TimeLoggerApp;
            if (app.delegate != null) {
                app.delegate.stopTogglTimer();
            }
        }
        // YES: do nothing. The background process re-armed itself when it fired.
        return true;
    }
}

class TimeLoggerSubMenuDelegate extends WatchUi.Menu2InputDelegate {
    var parent;
    var projectId;
    function initialize(p, projId) {
        Menu2InputDelegate.initialize();
        parent = p;
        projectId = projId;
    }
    function onSelect(item) {
        var description = item.getId();
        parent.startTogglTimer(description, projectId);
        // Pop sub-menu and main menu both
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
