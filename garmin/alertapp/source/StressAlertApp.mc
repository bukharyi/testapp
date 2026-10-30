import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class StressAlertApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new StressAlertView();
        return [view, new StressAlertDelegate(view)];
    }
}
