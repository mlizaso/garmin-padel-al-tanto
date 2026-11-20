import Toybox.Test;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;

(:test)
function openTouchSettingsFromHomeAndReady(logger as Test.Logger) as Boolean {
    var originalSetting = Application.Storage.getValue("pointTouch");
    try {
        Application.Storage.setValue("pointTouch", true);
        var view = new MatchView();
        var input = new MatchInput(view);
        Test.assertEqual(HOME, view.page);
        input.handleKey(WatchUi.KEY_DOWN);
        input.handleKey(WatchUi.KEY_DOWN);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(SETTINGS, view.page);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(SETTINGS, view.page);
        Test.assert(!view.touchOn);
        var reopened = new MatchView();
        Test.assert(!reopened.touchOn);
        input.tapAt(130, view.settingY(TOUCH_SETTING));
        Test.assert(!view.touchOn);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(HOME, view.page);
        input.tapAt(130, view.menuY(0));
        Test.assertEqual(HOME, view.page);

        input.handleKey(WatchUi.KEY_MENU);
        Test.assertEqual(SETTINGS, view.page);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assert(view.touchOn);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(HOME, view.page);
        input.tapAt(130, view.menuY(2));
        Test.assertEqual(SETTINGS, view.page);
        input.handleKey(WatchUi.KEY_ESC);

        view.applySetup(new PadelTemplate("", 0, 3, 0, false, false));
        Test.assertEqual(READY, view.page);
        input.handleKey(WatchUi.KEY_DOWN);
        Test.assertEqual(1, view.first);
        input.handleKey(WatchUi.KEY_MENU);
        Test.assertEqual(SETTINGS, view.page);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(READY, view.page);
        Test.assertEqual(1, view.first);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(HOME, view.page);
    } finally {
        if (originalSetting == null) { Application.Storage.deleteValue("pointTouch"); }
        else { Application.Storage.setValue("pointTouch", originalSetting); }
    }
    return true;
}

(:test)
function strokeDetectionRequiresOptInAndRemembersSettings(logger as Test.Logger) as Boolean {
    var originalStrokes = Application.Storage.getValue("strokeDetection");
    var originalTouch = Application.Storage.getValue("pointTouch");
    try {
        Application.Storage.deleteValue("strokeDetection");
        Application.Storage.setValue("pointTouch", false);
        var view = new MatchView();
        var input = new MatchInput(view);

        Test.assert(!view.recording.strokeDetectionOn);
        Test.assert(Application.Storage.getValue("strokeDetection") == null);
        input.handleKey(WatchUi.KEY_MENU);
        Test.assertEqual(SETTINGS, view.page);
        input.handleKey(WatchUi.KEY_DOWN);
        input.handleKey(WatchUi.KEY_DOWN);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assert(view.recording.strokeDetectionOn);
        Test.assertEqual(true, Application.Storage.getValue("strokeDetection"));
        Test.assert(!view.touchOn);
        Test.assertEqual(false, Application.Storage.getValue("pointTouch"));
        var optedIn = new MatchView();
        Test.assert(optedIn.recording.strokeDetectionOn);

        input.tapAt(130, view.settingY(STROKE_SETTING));
        Test.assert(view.recording.strokeDetectionOn);
        input.handleKey(WatchUi.KEY_UP);
        input.handleKey(WatchUi.KEY_UP);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assert(view.touchOn);
        Test.assert(view.recording.strokeDetectionOn);

        input.tapAt(130, view.settingY(STROKE_SETTING));
        Test.assert(!view.recording.strokeDetectionOn);
        Test.assert(view.touchOn);
        Test.assertEqual(true, Application.Storage.getValue("pointTouch"));
        var optedOut = new MatchView();
        Test.assert(!optedOut.recording.strokeDetectionOn);

        Application.Storage.setValue("strokeDetection", "true");
        var invalid = new MatchView();
        Test.assert(!invalid.recording.strokeDetectionOn);
    } finally {
        if (originalStrokes == null) { Application.Storage.deleteValue("strokeDetection"); }
        else { Application.Storage.setValue("strokeDetection", originalStrokes); }
        if (originalTouch == null) { Application.Storage.deleteValue("pointTouch"); }
        else { Application.Storage.setValue("pointTouch", originalTouch); }
    }
    return true;
}

(:test)
function changeLanguageFromHomeAndDuringRecording(logger as Test.Logger) as Boolean {
    var originalLanguage = Application.Storage.getValue("uiLanguage");
    var originalTouch = Application.Storage.getValue("pointTouch");
    var originalHistory = Application.Storage.getValue("lastScoredPoints");
    var view = new MatchVibrationTestView();
    var input = new MatchInput(view);
    try {
        PadelLanguage.setEnglish(false);
        view.touchOn = true;
        input.handleKey(WatchUi.KEY_DOWN);
        input.handleKey(WatchUi.KEY_DOWN);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(SETTINGS, view.page);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assert(!view.touchOn);
        input.handleKey(WatchUi.KEY_DOWN);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(LANGUAGE, view.page);
        Test.assert(!view.languageChoiceEnglish);
        input.tapAt(130, view.languageY(true));
        Test.assertEqual(LANGUAGE, view.page);
        input.handleKey(WatchUi.KEY_DOWN);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(SETTINGS, view.page);
        Test.assert(!PadelLanguage.isEnglish());
        input.handleKey(WatchUi.KEY_ENTER);
        input.handleKey(WatchUi.KEY_DOWN);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(SETTINGS, view.page);
        Test.assert(PadelLanguage.isEnglish());
        PadelLanguage.reload();
        Test.assert(PadelLanguage.isEnglish());
        Test.assert(!view.touchOn);
        input.handleKey(WatchUi.KEY_UP);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assert(view.touchOn);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(HOME, view.page);

        view.applySetup(new PadelTemplate("", 0, 3, 0, false, false));
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(PLAYING, view.page);
        var session = view.recording.session;
        Test.assert(session.isRecording());
        input.handleKey(WatchUi.KEY_UP);
        Test.assertEqual("15", view.score.pointsText(0));

        input.tapAt(164, view.yAt(91));
        input.tapAt(130, view.menuY(0));
        input.tapAt(130, view.settingY(LANGUAGE_SETTING));
        Test.assertEqual(LANGUAGE, view.page);
        Test.assert(view.languageChoiceEnglish);
        input.tapAt(130, view.languageY(false));
        Test.assertEqual(SETTINGS, view.page);
        Test.assert(!PadelLanguage.isEnglish());
        Test.assertEqual("es", Application.Storage.getValue("uiLanguage"));
        input.swipeDirection(WatchUi.SWIPE_RIGHT);
        Test.assertEqual(OPTIONS, view.page);
        input.swipeDirection(WatchUi.SWIPE_LEFT);
        Test.assertEqual(PLAYING, view.page);
        Test.assert(view.recording.session == session);
        Test.assert(session.isRecording());
        Test.assertEqual("15", view.score.pointsText(0));
        input.handleKey(WatchUi.KEY_UP);
        Test.assertEqual("30", view.score.pointsText(0));
    } finally {
        view.shutdown();
        restoreTestHistory(originalHistory);
        if (originalTouch == null) { Application.Storage.deleteValue("pointTouch"); }
        else { Application.Storage.setValue("pointTouch", originalTouch); }
        if (originalLanguage == null) { Application.Storage.deleteValue("uiLanguage"); }
        else { Application.Storage.setValue("uiLanguage", originalLanguage); }
        PadelLanguage.reload();
    }
    return true;
}

(:test)
function enabledHorizontalSwipesActAsBack(logger as Test.Logger) as Boolean {
    var view = new MatchVibrationTestView();
    var input = new MatchInput(view);
    view.touchOn = true;
    view.applySetup(new PadelTemplate("", 0, 3, 0, false, false));
    Test.assertEqual(READY, view.page);
    input.handleKey(WatchUi.KEY_MENU);
    Test.assertEqual(SETTINGS, view.page);
    input.swipeDirection(WatchUi.SWIPE_RIGHT);
    Test.assertEqual(READY, view.page);
    input.swipeDirection(WatchUi.SWIPE_LEFT);
    Test.assertEqual(HOME, view.page);
    input.tapAt(130, view.menuY(2));
    Test.assertEqual(SETTINGS, view.page);
    input.swipeDirection(WatchUi.SWIPE_RIGHT);
    Test.assertEqual(HOME, view.page);

    view.page = PLAYING;
    input.handleKey(WatchUi.KEY_UP);
    input.handleKey(WatchUi.KEY_UP);
    input.swipeDirection(WatchUi.SWIPE_UP);
    input.swipeDirection(WatchUi.SWIPE_DOWN);
    Test.assertEqual("30", view.score.pointsText(0));
    view.touchOn = false;
    input.swipeDirection(WatchUi.SWIPE_LEFT);
    input.swipeDirection(WatchUi.SWIPE_RIGHT);
    Test.assertEqual("30", view.score.pointsText(0));
    view.touchOn = true;
    input.swipeDirection(WatchUi.SWIPE_LEFT);
    Test.assertEqual("15", view.score.pointsText(0));

    input.handleKey(WatchUi.KEY_ENTER);
    input.tapAt(130, view.menuY(3));
    Test.assertEqual(CONFIRM_SAVE, view.page);
    input.swipeDirection(WatchUi.SWIPE_RIGHT);
    Test.assertEqual(PLAYING, view.page);
    Test.assertEqual("15", view.score.pointsText(0));
    return true;
}

(:test)
function recordMatchWithKeysAndTouch(logger as Test.Logger) as Boolean {
    var originalSetting = Application.Storage.getValue("pointTouch");
    var previousHistory = Application.Storage.getValue("lastScoredPoints");
    var view = new MatchView();
    var input = new MatchInput(view);
    view.touchOn = true;
    try {
        view.applySetup(new PadelTemplate("", 0, 3, 0, false, true));
        Test.assertEqual(READY, view.page);
        Test.assert(view.score.matchTieBreakEnabled);
        Test.assert(view.recording.session == null);
        input.handleKey(WatchUi.KEY_DOWN);
        Test.assertEqual(1, view.first);
        Test.assert(view.recording.session == null);
        input.tapAt(130, view.yAt(86));
        Test.assertEqual(PLAYING, view.page);
        Test.assert(view.recording.session.isRecording());
        input.tapAt(130, view.yAt(86));
        Test.assertEqual("0", view.score.pointsText(0));
        Test.assertEqual("0", view.score.pointsText(1));
        for (var rally = 0; rally < 3; rally++) { input.handleKey(WatchUi.KEY_UP); }
        input.tapAt(130, view.upperEdge() + 12);
        Test.assertEqual(1, view.score.games[1]);
        Test.assertEqual(0, view.score.server(view.first));
        input.tapAt(view.subtractX(), view.pointY(false));
        Test.assertEqual(0, view.score.games[1]);
        Test.assertEqual("40", view.score.pointsText(1));
        Test.assertEqual(1, view.score.server(view.first));
        input.tapAt(130, view.pointY(true));
        input.tapAt(130, view.lowerEdge() - 12);
        Test.assertEqual("15", view.score.pointsText(1));
        input.handleKey(WatchUi.KEY_ESC);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual("40", view.score.pointsText(1));
        Test.assertEqual(1, view.score.server(view.first));

        input.tapAt(164, view.yAt(91));
        Test.assertEqual(OPTIONS, view.page);
        input.tapAt(130, view.menuY(0));
        Test.assertEqual(SETTINGS, view.page);
        input.tapAt(130, view.settingY(TOUCH_SETTING));
        Test.assert(!view.touchOn);
        Test.assertEqual(SETTINGS, view.page);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(OPTIONS, view.page);
        input.handleKey(WatchUi.KEY_ESC);
        input.tapAt(130, view.upperEdge() + 12);
        input.tapAt(view.subtractX(), view.pointY(true));
        input.tapAt(164, view.yAt(91));
        Test.assertEqual(PLAYING, view.page);
        Test.assertEqual("40", view.score.pointsText(1));
        Test.assertEqual(0, view.score.games[1]);
        input.handleKey(WatchUi.KEY_DOWN);
        Test.assertEqual("15", view.score.pointsText(0));
        input.handleKey(WatchUi.KEY_MENU);
        Test.assertEqual(SETTINGS, view.page);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assert(view.touchOn);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(PLAYING, view.page);
        input.tapAt(130, view.divider());
        Test.assertEqual("15", view.score.pointsText(0));
        input.tapAt(130, view.lowerEdge() - 12);
        Test.assertEqual("30", view.score.pointsText(0));
        input.tapAt(view.subtractX(), view.pointY(true));
        Test.assertEqual("30", view.score.pointsText(1));
        Test.assertEqual("30", view.score.pointsText(0));
        input.tapAt(view.subtractX(), view.pointY(false));
        Test.assertEqual("15", view.score.pointsText(0));
        Test.assertEqual("30", view.score.pointsText(1));
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual("0", view.score.pointsText(0));
        Test.assertEqual("30", view.score.pointsText(1));

        input.handleKey(WatchUi.KEY_ENTER);
        for (var row = 0; row < 3; row++) { input.handleKey(WatchUi.KEY_DOWN); }
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(CONFIRM_SAVE, view.page);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(PLAYING, view.page);
        Test.assert(view.recording.session.isRecording());
        input.tapAt(164, view.yAt(91));
        input.tapAt(130, view.menuY(3));
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(FINISHED, view.page);
        Test.assert(view.recording.session == null);
    } finally {
        view.shutdown();
        restoreTestHistory(previousHistory);
        if (originalSetting == null) { Application.Storage.deleteValue("pointTouch"); }
        else { Application.Storage.setValue("pointTouch", originalSetting); }
    }
    return true;
}

(:test)
function chooseRulesDuringPlay(logger as Test.Logger) as Boolean {
    var originalRule = Application.Storage.getValue("deuceRule");
    try {
        Application.Storage.setValue("deuceRule", -1);
        var view = new MatchView();
        var input = new MatchInput(view);
        view.page = PLAYING;
        view.touchOn = true;
        input.handleKey(WatchUi.KEY_ENTER);
        input.handleKey(WatchUi.KEY_DOWN);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(RULES, view.page);
        input.handleKey(WatchUi.KEY_DOWN);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(0, view.score.selectedRule);
        Test.assertEqual(0, view.score.activeRule());
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(PLAYING, view.page);

        input.handleKey(WatchUi.KEY_UP);
        input.tapAt(164, view.yAt(91));
        input.tapAt(130, view.menuY(1));
        Test.assertEqual(RULES, view.page);
        input.tapAt(130, view.ruleY(2));
        input.tapAt(130, view.yAt(77));
        Test.assertEqual(OPTIONS, view.page);
        Test.assertEqual(2, view.score.selectedRule);
        Test.assertEqual(0, view.score.activeRule());
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(PLAYING, view.page);
        var restored = new MatchView();
        Test.assertEqual(2, restored.score.selectedRule);
    } finally {
        if (originalRule == null) { Application.Storage.deleteValue("deuceRule"); }
        else { Application.Storage.setValue("deuceRule", originalRule); }
    }
    return true;
}

(:test)
function recordAmericanoAcrossRounds(logger as Test.Logger) as Boolean {
    var previousHistory = Application.Storage.getValue("lastScoredPoints");
    var view = new MatchView();
    var input = new MatchInput(view);
    view.page = READY;
    view.touchOn = true;
    try {
        view.applySetup(new PadelTemplate("Americano 5", 5, 0, -1, false, false));
        Test.assertEqual(5, view.score.gameLimit);
        Test.assertEqual("Americano 5", view.setupName);
        Test.assertEqual(READY, view.page);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(PLAYING, view.page);
        var session = view.recording.session;
        Test.assert(session.isRecording());

        for (var game = 0; game < 5; game += 1) {
            var winner = game < 3 ? 0 : 1;
            var top = winner == game % 2;
            for (var rally = 0; rally < 3; rally += 1) {
                input.handleKey(top ? WatchUi.KEY_UP : WatchUi.KEY_DOWN);
            }
            input.tapAt(130, view.pointY(top));
        }
        Test.assertEqual(ROUND_OVER, view.page);
        Test.assertEqual("3-2", fitResultText(view.score));
        input.tapAt(130, view.pointY(false));
        Test.assertEqual(ROUND_OVER, view.page);
        Test.assert(session.isRecording());
        input.handleKey(WatchUi.KEY_DOWN);
        Test.assertEqual(CONFIRM_SAVE, view.page);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(ROUND_OVER, view.page);

        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(PLAYING, view.page);
        Test.assertEqual("40", view.score.pointsText(1));
        Test.assertEqual(1, view.score.games[1]);
        input.tapAt(130, view.pointY(false));
        input.tapAt(130, view.roundActionY(0));
        Test.assertEqual(ROUND_READY, view.page);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(ROUND_OVER, view.page);
        Test.assertEqual(0, view.score.completedRounds.size());

        input.tapAt(130, view.roundActionY(0));
        input.tapAt(130, view.yAt(61));
        Test.assertEqual(1, view.nextFirst);
        input.tapAt(130, view.nextRoundStartY());
        input.tapAt(130, view.nextRoundStartY());
        Test.assertEqual(PLAYING, view.page);
        Test.assertEqual(1, view.score.server(view.first));
        Test.assertEqual("0", view.score.pointsText(0));
        Test.assertEqual("0", view.score.pointsText(1));
        Test.assert(view.recording.session == session);
        Test.assert(session.isRecording());
        Test.assertEqual("3-2", fitResultText(view.score));
        Test.assertEqual(1, view.resultCount());

        for (var rally = 0; rally < 4; rally += 1) { input.handleKey(WatchUi.KEY_DOWN); }
        input.tapAt(130, view.pointY(true));
        Test.assertEqual("3-2 1-0*", fitResultText(view.score));
        input.handleKey(WatchUi.KEY_ENTER);
        input.tapAt(130, view.menuY(3));
        Test.assertEqual(CONFIRM_SAVE, view.page);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(FINISHED, view.page);
        Test.assert(view.recording.session == null);
        Test.assertEqual(2, view.resultIndex);
        input.handleKey(WatchUi.KEY_UP);
        Test.assertEqual(1, view.resultIndex);
        input.tapAt(130, view.yAt(74));
        input.tapAt(130, view.yAt(74));
        Test.assertEqual(0, view.resultIndex);
    } finally {
        view.shutdown();
        restoreTestHistory(previousHistory);
    }
    return true;
}

(:test)
function touchCorrectionCanCloseAmericano(logger as Test.Logger) as Boolean {
    var view = new MatchVibrationTestView();
    var input = new MatchInput(view);
    view.page = PLAYING;
    view.touchOn = true;
    view.score.configureFormat(5);
    view.score.setRule(-1);
    for (var game = 0; game < 4; game += 1) {
        for (var rally = 0; rally < 4; rally += 1) {
            input.handleKey(game % 2 == 0 ? WatchUi.KEY_UP : WatchUi.KEY_DOWN);
        }
    }
    for (var rally = 0; rally < 3; rally += 1) {
        input.handleKey(WatchUi.KEY_UP);
        input.handleKey(WatchUi.KEY_DOWN);
    }
    input.handleKey(WatchUi.KEY_UP);
    Test.assertEqual("AD", view.score.pointsText(0));
    var scored = view.vibrations.size();
    input.tapAt(view.subtractX(), view.pointY(false));
    Test.assertEqual(ROUND_OVER, view.page);
    Test.assertEqual("5-0", fitResultText(view.score));
    Test.assertEqual(scored, view.vibrations.size());
    input.handleKey(WatchUi.KEY_ESC);
    Test.assertEqual(PLAYING, view.page);
    Test.assertEqual(4, view.score.games[0]);
    Test.assertEqual("40", view.score.pointsText(0));
    Test.assertEqual("30", view.score.pointsText(1));
    return true;
}

(:test)
class MatchVibrationTestView extends MatchView {
    var vibrations as Array<Number> = [];

    function initialize() {
        MatchView.initialize();
    }

    function vibratePoint(pattern as Number) as Void {
        vibrations.add(pattern);
    }
}

(:test)
function vibrateOnlyForScoredPoints(logger as Test.Logger) as Boolean {
    var view = new MatchVibrationTestView();
    var input = new MatchInput(view);
    view.page = READY;
    view.touchOn = true;
    view.applySetup(new PadelTemplate("Dos juegos", 2, 0, 0, false, false));
    view.page = PLAYING;

    input.tapAt(130, view.divider());
    input.tapAt(view.subtractX() + view.yAt(8), view.pointY(true));
    input.tapAt(view.subtractX(), view.pointY(true));
    input.handleKey(WatchUi.KEY_ESC);
    input.tapAt(96, view.yAt(91));
    Test.assertEqual(HISTORY, view.page);
    input.handleKey(WatchUi.KEY_UP);
    input.handleKey(WatchUi.KEY_ESC);
    Test.assertEqual(PLAYING, view.page);
    Test.assertEqual(0, view.vibrations.size());
    Test.assertEqual(0, view.score.recentPointLines().size());

    input.tapAt(130, view.pointY(true));
    Test.assertEqual(RALLY_VIBRATION, view.vibrations[0]);
    input.handleKey(WatchUi.KEY_ESC);
    Test.assertEqual(1, view.vibrations.size());
    Test.assertEqual(0, view.score.recentPointLines().size());
    for (var rally = 0; rally < 4; rally += 1) { input.handleKey(WatchUi.KEY_UP); }
    Test.assertEqual(GAME_VIBRATION, view.vibrations[4]);
    for (var rally = 0; rally < 4; rally += 1) { input.handleKey(WatchUi.KEY_DOWN); }
    Test.assertEqual(ROUND_VIBRATION, view.vibrations[8]);
    Test.assertEqual(ROUND_OVER, view.page);
    view.addScore(true);
    Test.assertEqual(9, view.vibrations.size());
    return true;
}

(:test)
function closeUndoAndSaveBestOfThree(logger as Test.Logger) as Boolean {
    var previousHistory = Application.Storage.getValue("lastScoredPoints");
    var view = new MatchVibrationTestView();
    var input = new MatchInput(view);
    view.page = READY;
    view.touchOn = true;
    view.applySetup(new PadelTemplate("Mejor de 3", 0, 3, 0, false, false));
    try {
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(PLAYING, view.page);
        for (var game = 0; game < 12; game += 1) {
            for (var rally = 0; rally < 4; rally += 1) {
                input.handleKey(game % 2 == 0 ? WatchUi.KEY_UP : WatchUi.KEY_DOWN);
            }
        }
        Test.assertEqual(SET_VIBRATION, view.vibrations[23]);
        Test.assertEqual(MATCH_VIBRATION, view.vibrations[47]);
        Test.assertEqual(MATCH_OVER, view.page);
        Test.assertEqual(2, view.score.sets[0]);
        input.handleKey(WatchUi.KEY_DOWN);
        Test.assertEqual(MATCH_OVER, view.page);
        input.handleKey(WatchUi.KEY_UP);
        Test.assertEqual(HISTORY, view.page);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(MATCH_OVER, view.page);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(PLAYING, view.page);
        Test.assertEqual("40", view.score.pointsText(0));
        Test.assertEqual(48, view.vibrations.size());
        input.handleKey(WatchUi.KEY_DOWN);
        Test.assertEqual(MATCH_OVER, view.page);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(CONFIRM_SAVE, view.page);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(MATCH_OVER, view.page);
        input.handleKey(WatchUi.KEY_ENTER);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(FINISHED, view.page);
        Test.assert(view.recording.session == null);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(HISTORY, view.page);
        input.tapAt(130, view.yAt(88));
        Test.assertEqual(FINISHED, view.page);

        var reopened = new MatchView();
        var reopenedInput = new MatchInput(reopened);
        Test.assert(reopened.hasPreviousHistory());
        reopened.touchOn = true;
        reopenedInput.tapAt(130, reopened.menuY(3));
        Test.assertEqual(HISTORY, reopened.page);
        reopenedInput.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(HOME, reopened.page);
    } finally {
        view.shutdown();
        restoreTestHistory(previousHistory);
    }
    return true;
}

(:test)
function playAndCorrectOnlyGamesWithKeysAndTouch(logger as Test.Logger) as Boolean {
    var view = new MatchVibrationTestView();
    var input = new MatchInput(view);
    view.page = READY;
    view.touchOn = true;
    view.applySetup(new PadelTemplate("Americano rápido", 2, 0, 0, true, false));
    Test.assert(view.score.gamesOnly);
    view.page = PLAYING;

    input.tapAt(130, view.divider());
    input.tapAt(view.subtractX() + view.yAt(8), view.pointY(true));
    input.tapAt(view.subtractX(), view.pointY(true));
    Test.assertEqual(0, view.vibrations.size());
    input.handleKey(WatchUi.KEY_UP);
    Test.assertEqual(1, view.score.games[0]);
    Test.assertEqual(1, view.score.server(view.first));
    Test.assertEqual(GAME_VIBRATION, view.vibrations[0]);
    Test.assertEqual("0", view.score.pointsText(0));

    input.tapAt(view.subtractX(), view.pointY(true));
    Test.assertEqual(1, view.score.games[0]);
    input.tapAt(view.subtractX(), view.pointY(false));
    Test.assertEqual(0, view.score.games[0]);
    Test.assertEqual(0, view.score.recentPointLines().size());
    Test.assertEqual(1, view.vibrations.size());
    input.tapAt(130, view.pointY(false));
    Test.assertEqual(1, view.score.games[1]);
    Test.assertEqual(GAME_VIBRATION, view.vibrations[1]);

    input.handleKey(WatchUi.KEY_ENTER);
    input.tapAt(130, view.menuY(1));
    Test.assertEqual(HISTORY, view.page);
    Test.assertEqual(2, view.vibrations.size());
    input.handleKey(WatchUi.KEY_ESC);
    Test.assertEqual(OPTIONS, view.page);
    input.tapAt(130, view.menuY(2));
    Test.assertEqual(CONFIRM_SAVE, view.page);
    input.handleKey(WatchUi.KEY_ESC);
    Test.assertEqual(PLAYING, view.page);
    input.handleKey(WatchUi.KEY_UP);
    Test.assertEqual(ROUND_OVER, view.page);
    Test.assertEqual(ROUND_VIBRATION, view.vibrations[2]);
    input.handleKey(WatchUi.KEY_UP);
    Test.assertEqual(HISTORY, view.page);
    Test.assertEqual("R1 Riv.  Juegos 0–2", view.score.recentPointRecords()[0]);
    input.handleKey(WatchUi.KEY_ESC);
    input.handleKey(WatchUi.KEY_ESC);
    Test.assertEqual(PLAYING, view.page);
    Test.assertEqual(1, view.score.games[1]);
    Test.assertEqual(3, view.vibrations.size());
    return true;
}

(:test)
function finishAndSaveOnlyGamesAfterTiebreak(logger as Test.Logger) as Boolean {
    var previousHistory = Application.Storage.getValue("lastScoredPoints");
    var view = new MatchVibrationTestView();
    var input = new MatchInput(view);
    view.page = READY;
    view.touchOn = true;
    view.applySetup(new PadelTemplate("Solo juegos", 0, 3, 0, true, false));
    try {
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(PLAYING, view.page);
        for (var game = 0; game < 12; game += 1) { input.handleKey(WatchUi.KEY_UP); }
        Test.assertEqual(6, view.score.games[0]);
        Test.assertEqual(6, view.score.games[1]);
        Test.assert(view.score.tieBreak);
        Test.assertEqual(0, view.score.server(view.first));
        input.tapAt(130, view.pointY(false));
        Test.assertEqual("6-7", view.score.setScores[0]);
        Test.assertEqual(SET_VIBRATION, view.vibrations[12]);
        for (var game = 0; game < 6; game += 1) {
            input.handleKey(view.score.server(view.first) == 1 ? WatchUi.KEY_UP : WatchUi.KEY_DOWN);
        }
        Test.assertEqual(MATCH_OVER, view.page);
        Test.assertEqual(MATCH_VIBRATION, view.vibrations[18]);
        Test.assertEqual(2, view.score.sets[1]);
        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(PLAYING, view.page);
        Test.assertEqual(5, view.score.games[1]);
        Test.assertEqual(19, view.vibrations.size());
        input.handleKey(view.score.server(view.first) == 1 ? WatchUi.KEY_UP : WatchUi.KEY_DOWN);
        input.handleKey(WatchUi.KEY_ENTER);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(FINISHED, view.page);
        Test.assertEqual("6-7 0-6", fitResultText(view.score));
        Test.assert(savedHistoryUsesGames());
        Test.assertEqual(view.score.recentPointLines()[0], savedPointHistory()[0]);
    } finally {
        view.shutdown();
        restoreTestHistory(previousHistory);
    }
    return true;
}
