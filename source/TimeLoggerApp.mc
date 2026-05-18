import Toybox.Application;
import Toybox.WatchUi;

class TimeLoggerApp extends Application.AppBase {

    var delegate;

    (:glance, :background)
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        delegate = new TimeLoggerDelegate();
        return [ new TimeLoggerView(), delegate ];
    }

    (:glance)
    function getGlanceView() {
        return [ new TimeLoggerGlance() ];
    }

    (:background)
    function getServiceDelegate() {
        return [ new TimeLoggerCheckinService() ];
    }

}

function getApp() {
    return Application.getApp();
}
