import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;
import Toybox.Application.Storage;

(:test)
function scoreboardShowsLocalClockAndElapsedTime(logger as Test.Logger) as Boolean {
    Test.assertEqual("00:05", padelClockText(0, 5, true));
    Test.assertEqual("12:05 AM", padelClockText(0, 5, false));
    Test.assertEqual("12:00 PM", padelClockText(12, 0, false));
    Test.assertEqual("3:09 PM", padelClockText(15, 9, false));
    Test.assertEqual("00:00", padelDurationText(new MatchRecording().elapsedSeconds()));
    Test.assertEqual("59:59", padelDurationText(3599));
    Test.assertEqual("1:00:00", padelDurationText(3600));
    Test.assertEqual("10:07:01", padelDurationText(36421));
    return true;
}

(:test)
function americanoFitKeepsCompletedAndPartialRounds(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.configureFormat(5);
    for (var game = 0; game < 5; game++) {
        for (var rally = 0; rally < 4; rally++) { score.point(game % 2); }
    }
    Test.assertEqual("3-2", fitResultText(score));
    Test.assert(score.undo());
    Test.assertEqual("2-2*", fitResultText(score));
    score.point(0);
    Test.assert(score.nextRound());
    Test.assertEqual("3-2", fitResultText(score));
    score.point(1);
    Test.assertEqual("3-2 0-0*", fitResultText(score));
    for (var i = 0; i < 19; i++) { score.point(1); }
    Test.assertEqual("3-2 0-5", fitResultText(score));
    return true;
}

(:test)
function normalFitKeepsSetAndPartialGameScore(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    for (var i = 0; i < 24; i++) { score.point(0); }
    Test.assertEqual("6-0", fitResultText(score));
    for (var j = 0; j < 4; j++) { score.point(1); }
    Test.assertEqual("6-0 0-1*", fitResultText(score));
    return true;
}

(:test)
function fitKeepsPartialAndCompletedMatchTieBreakScores(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.configureBestOf(3);
    score.configureMatchTieBreak(true);
    for (var i = 0; i < 48; i += 1) { score.point(i / 24); }
    Test.assertEqual("6-0 0-6", fitResultText(score));
    for (var i = 0; i < 4; i += 1) { score.point(i % 2); }
    Test.assertEqual("6-0 0-6 [2-2]*", fitResultText(score));
    for (var i = 0; i < 8; i += 1) { score.point(1); }
    Test.assertEqual("6-0 0-6 [2-10]", fitResultText(score));
    return true;
}

(:test)
function fullRoundHistoryFitsGarminStringField(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.configureFormat(5);
    for (var i = 0; i < 40; i++) { score.completedRounds.add("3-2"); }
    var full = fitResultText(score);
    Test.assertEqual(159, full.length());
    Test.assertEqual("3-2", full.substring(0, 3));
    score.completedRounds.add("1-4");
    var trimmed = fitResultText(score);
    Test.assertEqual(159, trimmed.length());
    Test.assertEqual("... ", trimmed.substring(0, 4));
    Test.assertEqual("1-4", trimmed.substring(156, 159));
    return true;
}

(:test)
function americanoWritesTwoRoundsInOneActivity(logger as Test.Logger) as Boolean {
    var original = Storage.getValue("lastScoredPoints");
    var score = new PadelScore();
    score.configureFormat(5);
    var recording = new MatchRecording();
    Test.assert(recording.begin(score.gameLimit));
    for (var game = 0; game < 5; game++) {
        for (var rally = 0; rally < 4; rally++) { score.point(game % 2); }
    }
    Test.assert(score.nextRound());
    for (var i = 0; i < 20; i++) { score.point(1); }
    try {
        Test.assert(recording.save(score));
        var saved = savedPointHistory();
        var expected = score.recentPointLines();
        Test.assertEqual(5, saved.size());
        for (var n = 0; n < saved.size(); n++) { Test.assertEqual(expected[n], saved[n]); }
    } finally {
        restoreTestHistory(original);
    }
    return true;
}

(:test)
function savedHistoryDistinguishesGamesFromLegacyPoints(logger as Test.Logger) as Boolean {
    var original = Storage.getValue("lastScoredPoints");
    try {
        Storage.setValue("lastScoredPoints", ["Nos.  15–0"]);
        Test.assert(!savedHistoryUsesGames());
        Test.assertEqual(padelHistoryLine("Nos.  15–0"), savedPointHistory()[0]);
        var score = new PadelScore();
        score.configureFormat(6);
        score.configureGamesOnly(true);
        var recording = new MatchRecording();
        Test.assert(recording.begin(6));
        for (var i = 0; i < 6; i++) { Test.assert(score.game(i % 2)); }
        Test.assert(recording.save(score));
        Test.assert(savedHistoryUsesGames());
        var expected = score.recentPointLines();
        var saved = savedPointHistory();
        Test.assertEqual(5, saved.size());
        for (var k = 0; k < saved.size(); k++) { Test.assertEqual(expected[k], saved[k]); }
        Test.assertEqual("3-3", fitResultText(score));
    } finally {
        restoreTestHistory(original);
    }
    return true;
}

(:test)
function toggleStrokeDetectionDuringRecording(logger as Test.Logger) as Boolean {
    var originalStrokes = Storage.getValue("strokeDetection");
    var previousHistory = Storage.getValue("lastScoredPoints");
    var view = new MatchVibrationTestView();
    var input = new MatchInput(view);
    var counter = new RecordingStrokeTestCounter();
    view.recording.strokes = counter;
    view.page = READY;
    view.touchOn = true;
    try {
        view.recording.setStrokeDetection(false);
        input.handleKey(WatchUi.KEY_ENTER);
        Test.assertEqual(PLAYING, view.page);
        var session = view.recording.session;
        Test.assert(session.isRecording());
        Test.assertEqual(0, counter.starts);
        Test.assert(view.recording.hits == null);
        input.handleKey(WatchUi.KEY_UP);

        input.handleKey(WatchUi.KEY_MENU);
        Test.assertEqual(SETTINGS, view.page);
        input.tapAt(130, view.settingY(STROKE_SETTING));
        Test.assert(counter.sampling);
        Test.assertEqual(1, counter.starts);
        counter.available = true;
        counter.count = 3;

        input.tapAt(130, view.settingY(STROKE_SETTING));
        Test.assert(!counter.sampling);
        input.tapAt(130, view.settingY(STROKE_SETTING));
        Test.assert(counter.sampling);
        Test.assertEqual(2, counter.starts);
        Test.assert(counter.available);
        Test.assertEqual(3, counter.count);
        input.tapAt(130, view.settingY(STROKE_SETTING));
        Test.assert(!counter.sampling);

        input.handleKey(WatchUi.KEY_ESC);
        Test.assertEqual(PLAYING, view.page);
        Test.assert(view.recording.session == session);
        Test.assert(session.isRecording());
        Test.assert(view.touchOn);
        input.tapAt(130, view.pointY(true));
        Test.assertEqual("30", view.score.pointsText(0));

        view.finish();
        Test.assertEqual(FINISHED, view.page);
        Test.assert(view.recording.session == null);
        Test.assert(view.recording.hits != null);
    } finally {
        view.shutdown();
        restoreTestHistory(previousHistory);
        if (originalStrokes == null) { Storage.deleteValue("strokeDetection"); }
        else { Storage.setValue("strokeDetection", originalStrokes); }
    }
    return true;
}

(:test)
function saveWithoutStrokeSamplesOmitsStrokeField(logger as Test.Logger) as Boolean {
    var previousHistory = Storage.getValue("lastScoredPoints");
    var score = new PadelScore();
    var recording = new MatchRecording();
    var counter = new RecordingStrokeTestCounter();
    recording.strokes = counter;
    try {
        recording.setStrokeDetection(true);
        Test.assertEqual(0, counter.starts);
        Test.assert(recording.begin(score.gameLimit));
        Test.assert(counter.sampling);
        Test.assert(recording.hits == null);
        score.point(0);
        Test.assert(recording.save(score));
        Test.assert(!counter.sampling);
        Test.assert(recording.hits == null);
    } finally {
        if (recording.session != null) { recording.save(score); }
        restoreTestHistory(previousHistory);
    }
    return true;
}

(:test)
class RecordingStrokeTestCounter extends StrokeCounter {
    var starts as Number = 0;
    var sampling as Boolean = false;

    function start() as Void {
        starts++;
        sampling = true;
    }

    function stop() as Void {
        sampling = false;
    }
}

function restoreTestHistory(original as Storage.ValueType) as Void {
    if (original == null) { Storage.deleteValue("lastScoredPoints"); }
    else { Storage.setValue("lastScoredPoints", original); }
}
