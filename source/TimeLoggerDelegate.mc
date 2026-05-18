import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Communications;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;
import Toybox.Application;

class TimeLoggerDelegate extends WatchUi.BehaviorDelegate {

    var categories as Array<String> = ["Deep Work", "Meeting", "Admin", "Learning", "Run", "Personal"];

    // Toggl credentials live in source/Secrets.mc (gitignored).
    var workspaceId = Secrets.WORKSPACE_ID;
    var authHeader  = Secrets.AUTH_HEADER;

    function initialize() {
        BehaviorDelegate.initialize();

        var catString = Application.Properties.getValue("Categories");
        if (catString == null || catString.equals("")) {
            catString = "Deep Work,Meeting,Commute,Workout,Life Ops,Spanish,Reading,Personal";
        }
        categories = splitCategories(catString);
    }

    function splitCategories(str as Lang.String) as Lang.Array<Lang.String> {
        var result = [] as Lang.Array<Lang.String>;
        var start = 0;
        for (var i = 0; i < str.length(); i++) {
            if (str.substring(i, i + 1).equals(",")) {
                result.add(str.substring(start, i));
                start = i + 1;
            }
        }
        result.add(str.substring(start, str.length()));
        return result;
    }

    function onSelect() {
        var menu = new WatchUi.Menu2({:title=>"Log Activity"});

        var currentCategory = Application.Storage.getValue("currentCategory");
        if (currentCategory != null) {
            menu.addItem(new WatchUi.MenuItem("Stop: " + currentCategory, null, "__stop__", null));
        }

        for (var i = 0; i < categories.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(categories[i], null, categories[i], null));
        }
        WatchUi.pushView(menu, new TimeLoggerMenuDelegate(self), WatchUi.SLIDE_UP);
        return true;
    }

    function onBack() {
        // If a timer is running, BACK stops it instead of exiting the app.
        if (Application.Storage.getValue("currentEntryId") != null) {
            stopTogglTimer();
            return true;
        }
        return false;
    }

    function startTogglTimer(category) {
        var nowMoment = Time.now();
        var startIso = isoFromMoment(nowMoment);

        var url = "https://api.track.toggl.com/api/v9/workspaces/" + workspaceId + "/time_entries";

        var headers = {
            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
            "Authorization" => authHeader
        };

        // duration=-1 marks the entry as currently running.
        // Starting a new entry auto-stops any other running entry on this Toggl account.
        var params = {
            "description" => category,
            "created_with" => "GarminForerunner570",
            "start" => startIso,
            "duration" => -1,
            "workspace_id" => workspaceId.toNumber()
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => headers,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        // Stash so onStartReceive can persist on success.
        Application.Storage.setValue("pendingCategory", category);
        Application.Storage.setValue("pendingStartEpoch", nowMoment.value());
        Application.Storage.setValue("pendingStartIso", startIso);

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
            }
            WatchUi.showToast("Started", {:duration => 2000});
        } else {
            System.println("Toggl start error: " + responseCode);
            WatchUi.showToast("Err: " + responseCode, {:duration => 3000});
        }
        Application.Storage.deleteValue("pendingCategory");
        Application.Storage.deleteValue("pendingStartEpoch");
        Application.Storage.deleteValue("pendingStartIso");
    }

    function stopTogglTimer() {
        var entryId = Application.Storage.getValue("currentEntryId");
        var startEpoch = Application.Storage.getValue("currentStartEpoch");
        var startIso = Application.Storage.getValue("currentStartIso");
        var category = Application.Storage.getValue("currentCategory");

        if (entryId == null || startEpoch == null) {
            WatchUi.showToast("Nothing running", {:duration => 2000});
            Application.Storage.deleteValue("currentEntryId");
            Application.Storage.deleteValue("currentCategory");
            Application.Storage.deleteValue("currentStartEpoch");
            Application.Storage.deleteValue("currentStartIso");
            return;
        }

        // Clear local state up front so the view flips to idle immediately
        // and a second BACK press won't fire another stop request.
        Application.Storage.deleteValue("currentEntryId");
        Application.Storage.deleteValue("currentCategory");
        Application.Storage.deleteValue("currentStartEpoch");
        Application.Storage.deleteValue("currentStartIso");
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

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_PUT,
            :headers => headers,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        WatchUi.showToast("Stopping...", {:duration => 1000});
        Communications.makeWebRequest(url, params, options, method(:onStopReceive));
    }

    function onStopReceive(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        // Local state already cleared optimistically in stopTogglTimer.
        if (responseCode == 200 || responseCode == 404 || responseCode == 409) {
            WatchUi.showToast("Stopped", {:duration => 2000});
        } else {
            System.println("Toggl stop error: " + responseCode);
            WatchUi.showToast("Err: " + responseCode, {:duration => 3000});
        }
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

class TimeLoggerMenuDelegate extends WatchUi.Menu2InputDelegate {
    var parentDelegate;
    function initialize(delegate) {
        Menu2InputDelegate.initialize();
        parentDelegate = delegate;
    }
    function onSelect(item) {
        var id = item.getId();
        if (id.equals("__stop__")) {
            parentDelegate.stopTogglTimer();
        } else {
            parentDelegate.startTogglTimer(id);
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
