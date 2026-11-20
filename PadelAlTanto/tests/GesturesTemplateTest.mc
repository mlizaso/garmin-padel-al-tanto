import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

(:test)
function navigateTemplatesWithKeysAndSwipes(logger as Test.Logger) as Boolean {
    var view = new MatchView();
    view.touchOn = true;
    var menu = new PadelSetupMenu("Plantillas");
    for (var index = 0; index < 4; index++) {
        menu.addItem(new WatchUi.MenuItem("Plantilla " + index, null, index, {}));
    }
    var choices = new TemplateMenuTestChoices();
    var input = new PadelSetupMenuInput(menu, view, choices.method(:select), choices.method(:back));

    input.handleSwipe(WatchUi.SWIPE_UP);
    input.handleKey(WatchUi.KEY_ENTER);
    Test.assertEqual(1, choices.selected);
    input.handleSwipe(WatchUi.SWIPE_DOWN);
    input.handleKey(WatchUi.KEY_UP);
    input.handleKey(WatchUi.KEY_ENTER);
    Test.assertEqual(3, choices.selected);

    input.handleSwipe(WatchUi.SWIPE_LEFT);
    Test.assertEqual(1, choices.backCount);
    input.handleSwipe(WatchUi.SWIPE_RIGHT);
    Test.assertEqual(2, choices.backCount);

    view.touchOn = false;
    input.handleSwipe(WatchUi.SWIPE_UP);
    input.handleSwipe(WatchUi.SWIPE_LEFT);
    input.handleKey(WatchUi.KEY_ENTER);
    Test.assertEqual(3, choices.selected);
    Test.assertEqual(2, choices.backCount);
    input.handleKey(WatchUi.KEY_ESC);
    Test.assertEqual(3, choices.backCount);

    var firstVisible = menu.selectAt(130, 84);
    Test.assert(firstVisible != null);
    Test.assertEqual(1, (firstVisible as WatchUi.MenuItem).getId());
    Test.assert(menu.selectAt(6, 84) == null);
    Test.assert(menu.hitsBack(130, 231));
    return true;
}

(:test)
class TemplateMenuTestChoices {
    var selected as Number = -1;
    var backCount as Number = 0;

    function select(item as WatchUi.MenuItem) as Void {
        selected = item.getId() as Number;
    }

    function back() as Void {
        backCount++;
    }
}
