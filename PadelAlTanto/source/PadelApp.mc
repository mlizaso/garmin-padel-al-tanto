import Toybox.Application;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.FitContributor;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Lang;
import Toybox.WatchUi;

class PadelApp extends Application.AppBase {
    var screen;
    function initialize() {
        AppBase.initialize();
        PadelLanguage.reload();
    }
    function getInitialView() {
        screen = new MatchView();
        return [screen, new MatchInput(screen)];
    }
    function onStop(state) {
        if (screen != null) { screen.shutdown(); }
    }
}

class MatchRecording {
    var session;
    var us;
    var them;
    var hits;
    var result;
    var rounds;
    var strokes;
    var strokeDetectionOn as Boolean = false;
    function initialize() {
        strokes = new StrokeCounter();
    }
    function setStrokeDetection(enabled as Boolean) as Void {
        strokeDetectionOn = enabled;
        if (!enabled) {
            strokes.stop();
        } else if (session != null && session.isRecording()) {
            strokes.start();
        }
    }
    function begin(gameLimit as Number) {
        if (session != null) { return false; }
        strokes.count = 0;
        strokes.available = false;
        hits = null;
        try { Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]); } catch (e) { }
        try {
            session = ActivityRecording.createSession({
                :name => gameLimit > 0 ? "Americano " + gameLimit : tr("Pádel", "Padel"),
                :sport => Activity.SPORT_RACKET, :subSport => Activity.SUB_SPORT_PADEL
            });
            if (gameLimit > 0) {
                rounds = field("completed_rounds", 4);
                result = session.createField("round_scores", 5, FitContributor.DATA_TYPE_STRING,
                    { :mesgType => FitContributor.MESG_TYPE_SESSION, :count => 160 });
            } else {
                us = field("sets_us", 0);
                them = field("sets_them", 1);
                result = session.createField("set_scores", 3, FitContributor.DATA_TYPE_STRING,
                    { :mesgType => FitContributor.MESG_TYPE_SESSION, :count => 48 });
            }
            if (session.start()) {
                if (strokeDetectionOn) { strokes.start(); }
                return true;
            }
            System.println("Pádel: la sesión no ha podido iniciarse.");
        } catch (e) {
            System.println("Pádel: error al iniciar la sesión: " + e.getErrorMessage());
        }
        if (session != null) {
            try { session.discard(); } catch (e) { }
            session = null;
        }
        releaseHeartRate();
        return false;
    }
    private function releaseHeartRate() {
        try { Sensor.setEnabledSensors([]); } catch (e) { }
    }
    private function field(name, id) {
        return session.createField(name, id, FitContributor.DATA_TYPE_UINT16,
            { :mesgType => FitContributor.MESG_TYPE_SESSION });
    }
    private function saveStrokes() as Void {
        if (!strokes.available) { return; }
        try {
            if (hits == null) { hits = field("estimated_strokes", 2); }
            hits.setData(strokes.count);
        } catch (e) {
            System.println("Pádel: no se pudo incluir la estimación de golpes.");
        }
    }
    function save(score as PadelScore) {
        if (session == null) { return false; }
        try {
            if (session.isRecording()) {
                if (score.gameLimit > 0) {
                    rounds.setData(score.completedRounds.size() + (score.roundComplete() ? 1 : 0));
                } else {
                    us.setData(score.sets[0]);
                    them.setData(score.sets[1]);
                }
                saveStrokes();
                result.setData(fitResultText(score));
                if (!session.stop()) { return false; }
                strokes.stop();
            }
            if (session.save()) {
                session = null;
                releaseHeartRate();
                // The FIT has already been saved, even if local storage is full.
                try {
                    Application.Storage.setValue("lastScoredPoints", {
                        "gamesOnly" => score.gamesOnly,
                        "entries" => score.recentPointRecords()
                    });
                } catch (e) {
                    System.println("Pádel: no se pudo guardar el historial local.");
                }
                return true;
            }
        } catch (e) { }
        return false;
    }
}

function savedPointHistory() as Array<String> {
    var lines = [] as Array<String>;
    var stored = Application.Storage.getValue("lastScoredPoints");
    if (stored instanceof Dictionary) { stored = stored["entries"]; }
    if (stored instanceof Array) {
        for (var i = 0; i < stored.size() && lines.size() < 5; i++) {
            var line = stored[i];
            if (line instanceof String) { lines.add(padelHistoryLine(line)); }
        }
    }
    return lines;
}

function savedHistoryUsesGames() as Boolean {
    var stored = Application.Storage.getValue("lastScoredPoints");
    return stored instanceof Dictionary && stored["gamesOnly"] == true;
}

function hasCurrentResult(score as PadelScore) as Boolean {
    return score.games[0] + score.games[1] > 0 ||
        !score.pointsText(0).equals("0") || !score.pointsText(1).equals("0");
}

function fitResultText(score as PadelScore) as String {
    var americano = score.gameLimit > 0;
    var prior = americano ? score.completedRounds : score.setScores;
    var capacity = americano ? 160 : 48;
    var summary = "";
    if (hasCurrentResult(score)) {
        summary = score.games[0].toString() + "-" + score.games[1].toString();
        if (!score.roundComplete()) { summary += "*"; }
    }
    // Reserve one byte for NUL and four for the prefix if old scores are omitted.
    for (var i = prior.size() - 1; i >= 0; i--) {
        var entry = prior[i] + (summary.length() > 0 ? " " : "") + summary;
        if (entry.length() > capacity - (i > 0 ? 5 : 1)) {
            return "... " + summary;
        }
        summary = entry;
    }
    return summary.length() == 0 ? "0-0*" : summary;
}
