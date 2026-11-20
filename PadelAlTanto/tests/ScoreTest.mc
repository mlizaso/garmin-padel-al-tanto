import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;

(:test)
function scoreDeuceAndUndo(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    Test.assert(!score.undo());
    score.point(0);
    Test.assertEqual("15", score.pointsText(0));
    score.point(0);
    Test.assertEqual("30", score.pointsText(0));
    score.point(0);
    for (var i = 0; i < 3; i += 1) {
        score.point(1);
    }
    score.point(0);
    Test.assertEqual("AD", score.pointsText(0));
    score.point(1);
    Test.assertEqual("40", score.pointsText(0));
    Test.assertEqual("40", score.pointsText(1));
    score.point(1);
    score.point(1);
    Test.assertEqual(1, score.games[1]);
    Test.assert(score.undo());
    Test.assertEqual(0, score.games[1]);
    Test.assertEqual("AD", score.pointsText(1));
    return true;
}

(:test)
function scoreSetAndUndo(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    for (var i = 0; i < 24; i += 1) {
        score.point(0);
    }
    Test.assertEqual(1, score.sets[0]);
    Test.assertEqual("6-0", score.setScores[0]);
    Test.assert(!score.matchComplete());
    Test.assert(score.point(1));
    Test.assert(score.undo());
    Test.assert(score.undo());
    Test.assertEqual(0, score.sets[0]);
    Test.assertEqual(0, score.setScores.size());
    Test.assertEqual(5, score.games[0]);
    Test.assertEqual("40", score.pointsText(0));
    Test.assertEqual("0", score.pointsText(1));
    return true;
}

(:test)
function scoreTieBreakAndUndo(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.setRule(0);
    for (var game = 0; game < 12; game += 1) {
        for (var rally = 0; rally < 4; rally += 1) {
            score.point(game % 2);
        }
    }
    Test.assert(score.tieBreak);
    for (var i = 0; i < 12; i += 1) {
        Test.assert(!score.isDecidingPoint());
        score.point(i % 2);
    }
    Test.assert(!score.isDecidingPoint());
    score.point(1);
    Test.assertEqual("7", score.pointsText(1));
    Test.assert(score.tieBreak);
    score.point(1);
    Test.assertEqual("6-7", score.setScores[0]);
    Test.assertEqual(1, score.sets[1]);
    Test.assertEqual("Riv.  Sets 0–1", score.recentPointRecords()[0]);
    Test.assert(!score.tieBreak);
    Test.assert(score.undo());
    Test.assert(score.tieBreak);
    Test.assertEqual("7", score.pointsText(1));
    Test.assertEqual("6", score.pointsText(0));
    Test.assertEqual(6, score.games[1]);
    Test.assertEqual(0, score.sets[1]);
    Test.assertEqual("Riv.  6–7", score.recentPointRecords()[0]);
    return true;
}

(:test)
function scoreServiceOrder(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    for (var game = 0; game < 12; game += 1) {
        Test.assertEqual((1 + game) % 2, score.server(1));
        for (var rally = 0; rally < 4; rally += 1) {
            score.point(game % 2);
        }
    }
    var tieBreakServers = [1, 0, 0, 1, 1, 0, 0];
    for (var i = 0; i < tieBreakServers.size(); i += 1) {
        Test.assertEqual(tieBreakServers[i], score.server(1));
        score.point(0);
    }
    Test.assert(!score.tieBreak);
    Test.assertEqual(0, score.server(1));
    Test.assert(score.undo());
    Test.assert(score.tieBreak);
    Test.assertEqual(0, score.server(1));
    Test.assert(score.undo());
    Test.assert(score.undo());
    Test.assertEqual(1, score.server(1));
    return true;
}

(:test)
function matchTieBreakReplacesThirdSetAndKeepsServiceOrder(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.configureBestOf(3);
    score.configureMatchTieBreak(true);
    score.setRule(0);
    for (var i = 0; i < 6; i += 1) { score.point(i % 2); }
    score.setRule(-1);
    score.point(0);
    Test.assertEqual(1, score.games[0]);
    for (var i = 0; i < 20; i += 1) { score.point(0); }
    score.configureMatchTieBreak(false);
    Test.assert(score.matchTieBreakEnabled);
    Test.assert(!score.isMatchTieBreak());
    for (var game = 0; game < 12; game += 1) {
        for (var rally = 0; rally < 4; rally += 1) { score.point(game % 2); }
    }
    Test.assert(score.tieBreak);
    Test.assert(!score.isMatchTieBreak());
    for (var i = 0; i < 7; i += 1) { score.point(1); }
    Test.assert(score.isMatchTieBreak());
    Test.assert(score.tieBreak);
    Test.assertEqual("6-7", score.setScores[1]);
    Test.assertEqual(0, score.games[0] + score.games[1]);
    Test.assertEqual("0", score.pointsText(1));
    Test.assert(score.undo());
    Test.assert(score.tieBreak);
    Test.assert(!score.isMatchTieBreak());
    Test.assertEqual("6", score.pointsText(1));
    Test.assertEqual("6-0", score.setScores[0]);
    Test.assert(score.point(1));

    score.setRule(0);
    var servers = [0, 1, 1, 0];
    for (var i = 0; i < 18; i += 1) {
        Test.assertEqual(servers[i % 4], score.server(1));
        Test.assert(score.point(i % 2));
    }
    Test.assert(!score.isDecidingPoint());
    Test.assertEqual("9", score.pointsText(0));
    Test.assertEqual("9", score.pointsText(1));
    Test.assert(score.point(0));
    Test.assert(!score.matchComplete());
    Test.assert(score.point(1));
    Test.assert(score.point(0));
    Test.assert(!score.matchComplete());
    Test.assert(score.point(0));
    Test.assert(score.matchComplete());
    Test.assert(!score.isMatchTieBreak());
    Test.assert(!score.tieBreak);
    Test.assertEqual(2, score.sets[0]);
    Test.assertEqual(1, score.sets[1]);
    Test.assertEqual("[12-10]", score.setScores[2]);
    Test.assertEqual("Nos.  Super tie-break [12-10]", score.recentPointRecords()[0]);
    Test.assert(!score.point(1));

    Test.assert(score.undo());
    Test.assert(!score.matchComplete());
    Test.assert(score.isMatchTieBreak());
    Test.assert(score.tieBreak);
    Test.assertEqual(2, score.setScores.size());
    Test.assertEqual("11", score.pointsText(0));
    Test.assertEqual("10", score.pointsText(1));
    Test.assertEqual(1, score.server(1));
    Test.assert(score.removeLastPointFor(1));
    Test.assert(score.matchComplete());
    Test.assertEqual("[11-9]", score.setScores[2]);
    return true;
}

(:test)
function gamesOnlyRecordsAndCorrectsMatchTieBreakWinner(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.configureBestOf(3);
    score.configureGamesOnly(true);
    score.configureMatchTieBreak(true);
    for (var i = 0; i < 12; i += 1) { Test.assert(score.game(i / 6)); }
    Test.assert(score.isMatchTieBreak());
    Test.assert(score.tieBreak);
    Test.assert(!score.point(1));
    Test.assert(score.game(1));
    Test.assert(score.matchComplete());
    Test.assertEqual(2, score.sets[1]);
    Test.assertEqual("[L-W]", score.setScores[2]);
    Test.assertEqual("Riv.  Super tie-break [L-W]", score.recentPointRecords()[0]);
    Test.assertEqual(tr("Súper TB · Rivales", "Super TB · Opponents"), score.recentPointLines()[0]);
    Test.assert(!score.game(0));
    Test.assert(!score.removeLastGameFor(0));
    Test.assert(score.removeLastGameFor(1));
    Test.assert(score.isMatchTieBreak());
    Test.assert(score.tieBreak);
    Test.assertEqual(0, score.games[0] + score.games[1]);
    Test.assert(score.game(0));
    Test.assert(score.matchComplete());
    Test.assertEqual("[W-L]", score.setScores[2]);
    Test.assertEqual(tr("Súper TB · Nosotros", "Super TB · Us"), score.recentPointLines()[0]);
    return true;
}

(:test)
function matchTieBreakIsOnlyAvailableForBestOfThreeSets(logger as Test.Logger) as Boolean {
    var formats = [[0, 0], [0, 1], [0, 5], [5, 3]];
    for (var i = 0; i < formats.size(); i += 1) {
        var score = new PadelScore();
        score.configureFormat(formats[i][0]);
        score.configureBestOf(formats[i][1]);
        score.configureMatchTieBreak(true);
        Test.assert(!score.matchTieBreakEnabled);
    }
    return true;
}

(:test)
function scoreDecidingPointRules(logger as Test.Logger) as Boolean {
    for (var winner = 0; winner <= 1; winner += 1) {
        for (var rule = 0; rule <= 4; rule += 1) {
            var score = new PadelScore();
            score.setRule(rule);
            for (var i = 0; i < 6; i += 1) {
                Test.assert(!score.isDecidingPoint());
                score.point(i % 2);
            }
            for (var count = 0; count < rule; count += 1) {
                Test.assert(!score.isDecidingPoint());
                score.point(0);
                Test.assert(!score.isDecidingPoint());
                Test.assertEqual("AD", score.pointsText(0));
                score.point(1);
            }
            Test.assert(score.isDecidingPoint());
            score.point(winner);
            Test.assertEqual(1, score.games[winner]);
            Test.assert(!score.isDecidingPoint());
            Test.assert(score.undo());
            Test.assertEqual(0, score.games[winner]);
            Test.assert(score.isDecidingPoint());
            Test.assertEqual("40", score.pointsText(0));
            Test.assertEqual("40", score.pointsText(1));
        }
    }
    return true;
}

(:test)
function scoreDefersRuleChangeAndReplaysIt(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.setRule(0);
    for (var i = 0; i < 6; i += 1) {
        score.point(i % 2);
    }
    score.setRule(-1);
    Test.assertEqual(0, score.activeRule());
    Test.assert(score.isDecidingPoint());
    score.point(1);
    Test.assertEqual(-1, score.activeRule());
    score.setRule(1);
    Test.assertEqual(1, score.activeRule());
    score.point(0);
    score.setRule(2);
    Test.assertEqual(1, score.activeRule());
    Test.assert(score.undo());
    Test.assertEqual(2, score.activeRule());
    Test.assert(score.undo());
    Test.assertEqual(2, score.selectedRule);
    Test.assertEqual(0, score.activeRule());
    Test.assert(score.isDecidingPoint());
    score.point(0);
    Test.assertEqual(1, score.games[0]);
    Test.assertEqual(2, score.activeRule());
    return true;
}

(:test)
function scoreTeamCorrectionStaysInCurrentGame(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    Test.assert(!score.removeLastPointFor(0));
    for (var i = 0; i < 4; i += 1) {
        score.point(0);
    }
    Test.assert(!score.removeLastPointFor(1));
    Test.assert(score.removeLastPointFor(0));
    Test.assertEqual(0, score.games[0]);
    Test.assertEqual("40", score.pointsText(0));
    score.point(0);
    score.point(1);
    Test.assert(!score.removeLastPointFor(0));
    score.point(0);
    score.point(1);
    Test.assert(score.removeLastPointFor(0));
    Test.assertEqual("0", score.pointsText(0));
    Test.assertEqual("30", score.pointsText(1));
    Test.assertEqual(1, score.games[0]);
    Test.assert(score.undo());
    Test.assertEqual("15", score.pointsText(1));
    return true;
}

(:test)
function scoreTeamCorrectionCanCloseGame(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    for (var i = 0; i < 6; i += 1) {
        score.point(i % 2);
    }
    score.point(0);
    score.setRule(0);
    Test.assertEqual("AD", score.pointsText(0));
    var lastPoints = score.recentPointRecords();
    Test.assertEqual(5, lastPoints.size());
    Test.assertEqual("Nos.  AD–40", lastPoints[0]);
    Test.assertEqual("Riv.  40–40", lastPoints[1]);
    Test.assertEqual("Nos.  30–15", lastPoints[4]);
    // A-B-A-B-A-B-A becomes A-B-A-B-A-A (a 4-2 win).
    Test.assert(score.removeLastPointFor(1));
    Test.assertEqual(1, score.games[0]);
    Test.assertEqual(0, score.activeRule());
    lastPoints = score.recentPointRecords();
    Test.assertEqual(5, lastPoints.size());
    Test.assertEqual("Nos.  Juegos 1–0", lastPoints[0]);
    Test.assertEqual("Nos.  40–30", lastPoints[1]);
    Test.assert(score.undo());
    Test.assertEqual(0, score.games[0]);
    Test.assertEqual("40", score.pointsText(0));
    Test.assertEqual("30", score.pointsText(1));
    Test.assertEqual(-1, score.activeRule());
    Test.assertEqual("Nos.  40–30", score.recentPointRecords()[0]);
    return true;
}

(:test)
function americanoCountsTotalGames(logger as Test.Logger) as Boolean {
    // Limit, games won by team 0, games won by team 1.
    var cases = [[7, 4, 2], [7, 5, 0], [7, 6, 0], [7, 5, 2], [7, 6, 1],
        [7, 7, 0], [5, 3, 2], [5, 5, 0], [5, 0, 5], [1, 0, 1], [6, 3, 3], [99, 52, 47]];
    for (var i = 0; i < cases.size(); i += 1) {
        var spec = cases[i];
        var score = new PadelScore();
        score.configureFormat(spec[0]);
        for (var team = 0; team < 2; team += 1) {
            for (var game = 0; game < spec[team + 1]; game += 1) {
                Test.assert(!score.roundComplete());
                for (var point = 0; point < 4; point += 1) {
                    score.point(team);
                }
            }
        }
        Test.assertEqual(spec[0] == spec[1] + spec[2], score.roundComplete());
        Test.assertEqual(spec[1], score.games[0]);
        Test.assertEqual(spec[2], score.games[1]);
        Test.assert(!score.tieBreak);
        Test.assertEqual(0, score.setScores.size());
        Test.assertEqual(0, score.sets[0]);
        Test.assertEqual(0, score.sets[1]);
        Test.assertEqual(0, score.completedRounds.size());
    }
    return true;
}

(:test)
function americanoConfirmAndUndo(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.configureFormat(5);
    score.setRule(0);
    Test.assert(!score.nextRound());
    for (var i = 0; i < 20; i += 1) {
        score.point(1);
    }
    Test.assert(score.roundComplete());
    score.point(0);
    Test.assertEqual("0", score.pointsText(0));
    Test.assertEqual(5, score.games[1]);
    Test.assert(!score.removeLastPointFor(0));
    Test.assert(score.removeLastPointFor(1));
    Test.assert(!score.roundComplete());
    Test.assertEqual(4, score.games[1]);
    Test.assertEqual("40", score.pointsText(1));
    score.point(1);
    Test.assert(score.undo());
    Test.assert(!score.roundComplete());
    for (var j = 0; j < 4; j += 1) {
        score.point(0);
    }
    Test.assert(score.nextRound());
    Test.assertEqual("1-4", score.completedRounds[0]);
    Test.assert(!score.roundComplete());
    Test.assert(!score.undo());
    Test.assert(!score.removeLastPointFor(0));
    Test.assert(!score.nextRound());
    Test.assertEqual(0, score.games[0]);
    Test.assertEqual(0, score.games[1]);
    Test.assertEqual(1, score.server(1));
    Test.assertEqual(0, score.activeRule());
    score.configureFormat(7);
    Test.assertEqual(5, score.gameLimit);
    score.point(1);
    Test.assert(score.undo());
    Test.assertEqual("1-4", score.completedRounds[0]);
    return true;
}

(:test)
function scoreLocksFormatAtFirstRally(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.configureFormat(5);
    score.configureFormat(4);
    score.configureFormat(-1);
    score.configureFormat(100);
    Test.assertEqual(4, score.gameLimit);
    score.configureFormat(7);
    score.configureFormat(0);
    score.configureBestOf(2);
    Test.assertEqual(0, score.bestOf);
    score.configureBestOf(3);
    score.point(0);
    Test.assert(score.undo());
    score.configureFormat(7);
    score.configureBestOf(5);
    score.configureGamesOnly(true);
    Test.assertEqual(0, score.gameLimit);
    Test.assertEqual(3, score.bestOf);
    Test.assert(!score.gamesOnly);
    Test.assert(!score.game(0));
    Test.assert(!score.roundComplete());
    Test.assert(!score.nextRound());
    return true;
}

(:test)
function normalMatchRequiresMajorityOfSets(logger as Test.Logger) as Boolean {
    var cases = [[1, 0], [3, 0], [3, 1], [5, 0], [5, 2]];
    for (var i = 0; i < cases.size(); i += 1) {
        var score = new PadelScore();
        var bestOf = cases[i][0];
        var losingSets = cases[i][1];
        var winningSets = (bestOf + 1) / 2;
        score.configureBestOf(bestOf);
        for (var set = 0; set < losingSets + winningSets; set += 1) {
            var team = set < losingSets ? 0 : 1;
            for (var point = 0; point < 24; point += 1) {
                Test.assert(!score.matchComplete());
                Test.assert(score.point(team));
            }
        }
        Test.assert(score.matchComplete());
        Test.assert(!score.roundComplete());
        Test.assert(!score.nextRound());
        Test.assert(!score.point(0));
        Test.assertEqual(losingSets, score.sets[0]);
        Test.assertEqual(winningSets, score.sets[1]);
        Test.assertEqual("Riv.  Sets " + losingSets + "–" + winningSets, score.recentPointRecords()[0]);
        Test.assert(score.undo());
        Test.assert(!score.matchComplete());
        Test.assertEqual("Riv.  0–40", score.recentPointRecords()[0]);
        Test.assert(score.point(1));
        Test.assert(score.matchComplete());
    }
    return true;
}

(:test)
function correctionCanCloseNormalMatch(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.configureBestOf(1);
    for (var i = 0; i < 20; i += 1) {
        score.point(0);
    }
    for (var i = 0; i < 7; i += 1) {
        score.point(i % 2);
    }
    Test.assert(!score.matchComplete());
    Test.assert(score.removeLastPointFor(1));
    Test.assert(score.matchComplete());
    Test.assertEqual("Nos.  Sets 1–0", score.recentPointRecords()[0]);
    Test.assert(score.removeLastPointFor(0));
    Test.assert(!score.matchComplete());
    Test.assertEqual(5, score.games[0]);
    Test.assertEqual("Nos.  40–30", score.recentPointRecords()[0]);
    return true;
}

(:test)
function americanoHistorySurvivesRoundConfirmation(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.configureBestOf(1);
    score.configureFormat(2);
    Test.assertEqual(0, score.recentPointRecords().size());
    for (var i = 0; i < 8; i += 1) {
        Test.assert(score.point(i / 4));
    }
    Test.assert(score.roundComplete());
    Test.assert(!score.matchComplete());
    Test.assert(!score.point(0));
    var confirmed = score.recentPointRecords();
    Test.assertEqual(5, confirmed.size());
    Test.assertEqual("R1 Riv.  Juegos 1–1", confirmed[0]);
    Test.assertEqual("R1 Nos.  Juegos 1–0", confirmed[4]);
    Test.assert(score.nextRound());
    Test.assertEqual("1-1", score.completedRounds[0]);
    Test.assertEqual(confirmed[0], score.recentPointRecords()[0]);
    Test.assert(score.point(1));
    Test.assert(score.point(0));
    Test.assertEqual("R2 Nos.  15–15", score.recentPointRecords()[0]);
    Test.assert(score.removeLastPointFor(1));
    Test.assertEqual("R2 Nos.  15–0", score.recentPointRecords()[0]);
    Test.assertEqual(confirmed[0], score.recentPointRecords()[1]);
    Test.assert(score.undo());
    Test.assert(!score.undo());
    var recovered = score.recentPointRecords();
    Test.assertEqual(5, recovered.size());
    for (var i = 0; i < 5; i += 1) {
        Test.assertEqual(confirmed[i], recovered[i]);
    }
    return true;
}

(:test)
function gameTrackingRecordsOneEventAndCorrectsLatestWinner(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    Test.assert(!score.gamesOnly);
    Test.assert(!score.game(0));
    score.configureGamesOnly(true);
    score.setRule(0);
    Test.assert(score.gamesOnly);
    Test.assert(!score.point(0));
    Test.assert(!score.removeLastGameFor(0));
    Test.assertEqual(0, score.recentPointRecords().size());

    Test.assert(score.game(0));
    Test.assertEqual(1, score.games[0]);
    Test.assertEqual(1, score.server(0));
    Test.assertEqual("0", score.pointsText(0));
    Test.assertEqual("0", score.pointsText(1));
    Test.assert(!score.isDecidingPoint());
    Test.assert(!score.removeLastPointFor(0));
    Test.assertEqual(1, score.recentPointRecords().size());
    Test.assertEqual("Nos.  Juegos 1–0", score.recentPointRecords()[0]);
    score.configureGamesOnly(false);
    Test.assert(score.gamesOnly);

    Test.assert(score.game(1));
    Test.assertEqual(0, score.server(0));
    Test.assert(!score.removeLastGameFor(0));
    Test.assertEqual("Riv.  Juegos 1–1", score.recentPointRecords()[0]);
    Test.assert(score.removeLastGameFor(1));
    Test.assertEqual(0, score.games[1]);
    Test.assertEqual("Nos.  Juegos 1–0", score.recentPointRecords()[0]);
    Test.assert(score.undo());
    score.configureGamesOnly(false);
    Test.assert(score.gamesOnly);
    Test.assertEqual(0, score.games[0]);
    Test.assertEqual(0, score.server(0));
    Test.assertEqual(0, score.recentPointRecords().size());
    Test.assert(!score.undo());
    return true;
}

(:test)
function gameTrackingResolvesTiebreakAndReopensMatch(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.configureGamesOnly(true);
    score.configureBestOf(1);
    for (var i = 0; i < 12; i += 1) {
        Test.assertEqual((1 + i) % 2, score.server(1));
        Test.assert(score.game(i % 2));
    }
    Test.assert(score.tieBreak);
    Test.assert(!score.matchComplete());
    Test.assertEqual(1, score.server(1));
    Test.assert(!score.point(0));
    Test.assertEqual("Riv.  Juegos 6–6", score.recentPointRecords()[0]);
    Test.assert(score.game(1));
    Test.assert(!score.tieBreak);
    Test.assert(score.matchComplete());
    Test.assertEqual("6-7", score.setScores[0]);
    Test.assertEqual("Riv.  Set 6–7 · Sets 0–1", score.recentPointRecords()[0]);
    Test.assertEqual(0, score.server(1));
    Test.assert(!score.game(0));
    Test.assert(score.undo());
    Test.assert(score.tieBreak);
    Test.assert(!score.matchComplete());
    Test.assertEqual(0, score.setScores.size());
    Test.assertEqual(1, score.server(1));
    Test.assertEqual("Riv.  Juegos 6–6", score.recentPointRecords()[0]);
    Test.assert(score.game(0));
    Test.assert(score.matchComplete());
    Test.assertEqual("7-6", score.setScores[0]);
    Test.assertEqual(0, score.server(1));
    return true;
}

(:test)
function gameTrackingCompletesTiedAmericanoAndKeepsHistory(logger as Test.Logger) as Boolean {
    var score = new PadelScore();
    score.configureGamesOnly(true);
    score.configureFormat(6);
    for (var i = 0; i < 6; i += 1) {
        Test.assert(!score.roundComplete());
        Test.assert(score.game(i % 2));
    }
    Test.assert(score.roundComplete());
    Test.assert(!score.game(0));
    var lines = score.recentPointRecords();
    Test.assertEqual(5, lines.size());
    Test.assertEqual("R1 Riv.  Juegos 3–3", lines[0]);
    Test.assertEqual("R1 Riv.  Juegos 1–1", lines[4]);
    Test.assert(score.removeLastGameFor(1));
    Test.assert(!score.roundComplete());
    Test.assertEqual("R1 Nos.  Juegos 3–2", score.recentPointRecords()[0]);
    Test.assert(score.game(1));
    Test.assert(score.nextRound());
    Test.assertEqual("3-3", score.completedRounds[0]);
    Test.assert(!score.undo());
    Test.assertEqual("R1 Riv.  Juegos 3–3", score.recentPointRecords()[0]);

    Test.assert(score.game(0));
    Test.assertEqual("R2 Nos.  Juegos 1–0", score.recentPointRecords()[0]);
    Test.assert(score.undo());
    Test.assertEqual("R1 Riv.  Juegos 3–3", score.recentPointRecords()[0]);
    return true;
}

(:test)
function recentHistoryFollowsLanguageAcrossRoundsAndUndo(logger as Test.Logger) as Boolean {
    var originalLanguage = Storage.getValue("uiLanguage");
    try {
        PadelLanguage.setEnglish(false);
        Test.assertEqual("Súper TB · Rivales", padelHistoryLine("Riv.  Super tie-break [L-W]"));
        var score = new PadelScore();
        score.configureFormat(2);
        score.configureGamesOnly(true);
        Test.assert(score.game(0));
        Test.assert(score.game(1));
        Test.assert(score.nextRound());
        Test.assertEqual("R1 Riv.  Juegos 1–1", score.recentPointLines()[0]);

        PadelLanguage.setEnglish(true);
        Test.assertEqual("Super TB · Us", padelHistoryLine("Nos.  Super tie-break [W-L]"));
        Test.assertEqual("R1 Opp.  Games 1–1", score.recentPointLines()[0]);
        Test.assert(score.game(0));
        Test.assertEqual("R2 Us  Games 1–0", score.recentPointLines()[0]);
        Test.assertEqual("R2 Nos.  Juegos 1–0", score.recentPointRecords()[0]);

        PadelLanguage.setEnglish(false);
        Test.assertEqual("R2 Nos.  Juegos 1–0", score.recentPointLines()[0]);
        Test.assert(score.undo());
        Test.assertEqual("R1 Riv.  Juegos 1–1", score.recentPointLines()[0]);
    } finally {
        if (originalLanguage == null) { Storage.deleteValue("uiLanguage"); }
        else { Storage.setValue("uiLanguage", originalLanguage); }
        PadelLanguage.reload();
    }
    return true;
}
