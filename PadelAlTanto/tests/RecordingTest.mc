import Toybox.Lang;
import Toybox.Test;
import Toybox.Application.Storage;

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

function restoreTestHistory(original as Storage.ValueType) as Void {
    if (original == null) { Storage.deleteValue("lastScoredPoints"); }
    else { Storage.setValue("lastScoredPoints", original); }
}
