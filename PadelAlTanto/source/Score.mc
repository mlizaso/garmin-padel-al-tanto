import Toybox.Lang;

const PADEL_HISTORY_US = "Nos.";
const PADEL_HISTORY_OPPONENTS = "Riv.";
const PADEL_HISTORY_GAMES_PREFIX = "Juegos ";

function padelHistoryLine(record as String) as String {
    if (!PadelLanguage.isEnglish()) { return record; }

    var separator = record.find("  ");
    if (separator == null || separator < 4 || separator + 2 >= record.length()) { return record; }
    var teamStart = separator - 4;
    var team = record.substring(teamStart, separator) as String;
    if (!team.equals(PADEL_HISTORY_US) && !team.equals(PADEL_HISTORY_OPPONENTS)) { return record; }

    var round = teamStart == 0 ? "" : record.substring(0, teamStart) as String;
    var who = team.equals(PADEL_HISTORY_US) ? "Us" : "Opp.";
    var result = record.substring(separator + 2, record.length()) as String;
    if (result.find(PADEL_HISTORY_GAMES_PREFIX) == 0 && result.length() > PADEL_HISTORY_GAMES_PREFIX.length()) {
        result = "Games " + result.substring(PADEL_HISTORY_GAMES_PREFIX.length(), result.length());
    }
    return round + who + "  " + result;
}

class PadelScore {
    private const HISTORY_SIZE = 5;

    var games as Array<Number> = [0, 0];
    var sets as Array<Number> = [0, 0];
    var setScores as Array<String> = [];
    var tieBreak as Boolean = false;
    // Zero uses normal sets. A positive limit counts games per Americano round.
    var gameLimit as Number = 0;
    // Zero leaves normal matches open-ended.
    var bestOf as Number = 0;
    var gamesOnly as Boolean = false;
    var completedRounds as Array<String> = [];
    // -1 is unlimited advantage; 0 is golden point at the first deuce.
    var selectedRule as Number = -1;

    private var points as Array<Number> = [0, 0];
    private var completedGames as Number = 0;
    private var eventWinners as Array<Number> = [];
    private var gameRules as Array<Number> = [];
    private var recentHistory as Array<String> = [];
    private var confirmedHistory as Array<String> = [];
    private var formatLocked as Boolean = false;
    private var labels as Array<String> = ["0", "15", "30", "40"];

    private function resetScore() {
        points = [0, 0];
        games = [0, 0];
        sets = [0, 0];
        setScores = [];
        tieBreak = false;
        completedGames = 0;
    }

    function point(team as Number) as Boolean {
        return !gamesOnly && addEvent(team);
    }

    function game(team as Number) as Boolean {
        return gamesOnly && addEvent(team);
    }

    private function addEvent(team as Number) as Boolean {
        if (roundComplete() || matchComplete()) {
            return false;
        }
        formatLocked = true;
        eventWinners.add(team);
        applyEvent(team, true);
        return true;
    }

    function configureFormat(limit as Number) as Void {
        if (!formatLocked && limit >= 0 && limit <= 99) {
            gameLimit = limit;
        }
    }

    function configureBestOf(limit as Number) as Void {
        if (!formatLocked && (limit == 0 || limit == 1 || limit == 3 || limit == 5)) {
            bestOf = limit;
        }
    }

    function configureGamesOnly(enabled as Boolean) as Void {
        if (!formatLocked) {
            gamesOnly = enabled;
        }
    }

    function matchComplete() as Boolean {
        var target = (bestOf + 1) / 2;
        return gameLimit == 0 && bestOf > 0 && (sets[0] >= target || sets[1] >= target);
    }

    function roundComplete() as Boolean {
        return gameLimit > 0 && completedGames >= gameLimit;
    }

    function nextRound() as Boolean {
        if (!roundComplete()) {
            return false;
        }
        completedRounds.add(games[0].toString() + "-" + games[1].toString());
        confirmedHistory = recentHistory.slice(0, recentHistory.size());
        eventWinners = [];
        gameRules = [];
        resetScore();
        return true;
    }

    function setRule(rule as Number) as Void {
        selectedRule = rule;
    }

    function activeRule() as Number {
        if (completedGames < gameRules.size()) {
            return gameRules[completedGames];
        }
        return selectedRule;
    }

    function isDecidingPoint() as Boolean {
        var rule = activeRule();
        return !gamesOnly && !tieBreak && rule >= 0 && points[0] == points[1] &&
            points[0] - 3 >= rule;
    }

    function removeLastPointFor(team as Number) as Boolean {
        var size = eventWinners.size();
        if (gamesOnly || size == 0) {
            return false;
        }
        var currentGameSize = points[0] + points[1];
        // At 0-0 the point that just closed the previous game can be corrected.
        var first = currentGameSize == 0 ? size - 1 : size - currentGameSize;
        for (var i = size - 1; i >= first; i -= 1) {
            if (eventWinners[i] == team) {
                removeEventAt(i);
                return true;
            }
        }
        return false;
    }

    function removeLastGameFor(team as Number) as Boolean {
        var last = eventWinners.size() - 1;
        // A correction keeps the order of already credited games.
        return gamesOnly && last >= 0 && eventWinners[last] == team && undo();
    }

    function undo() as Boolean {
        if (eventWinners.size() == 0) {
            return false;
        }
        removeEventAt(eventWinners.size() - 1);
        return true;
    }

    private function removeEventAt(index as Number) as Void {
        for (var pos = index; pos + 1 < eventWinners.size(); pos += 1) {
            eventWinners[pos] = eventWinners[pos + 1];
        }
        eventWinners = eventWinners.slice(0, eventWinners.size() - 1);
        resetScore();
        recentHistory = confirmedHistory.slice(0, confirmedHistory.size());
        var historyStart = eventWinners.size() - HISTORY_SIZE;
        for (var i = 0; i < eventWinners.size(); i += 1) {
            applyEvent(eventWinners[i], i >= historyStart);
        }
        if (gamesOnly) {
            return;
        }
        // Drop only the rules of games whose opening point was undone.
        var startedGames = completedGames;
        if (points[0] + points[1] > 0) {
            startedGames += 1;
        }
        gameRules = gameRules.slice(0, startedGames);
    }

    function recentPointLines() as Array<String> {
        var lines = recentPointRecords();
        for (var i = 0; i < lines.size(); i++) {
            lines[i] = padelHistoryLine(lines[i]);
        }
        return lines;
    }

    // Keep stored history in the original format so it can be read in either language.
    function recentPointRecords() as Array<String> {
        var newestFirst = [] as Array<String>;
        for (var i = recentHistory.size() - 1; i >= 0; i -= 1) {
            newestFirst.add(recentHistory[i]);
        }
        return newestFirst;
    }

    private function rememberEvent(team as Number, result as String) as Void {
        var who = team == 0 ? PADEL_HISTORY_US : PADEL_HISTORY_OPPONENTS;
        var round = gameLimit > 0 ? "R" + (completedRounds.size() + 1) + " " : "";
        if (recentHistory.size() >= HISTORY_SIZE) {
            recentHistory = recentHistory.slice(1, HISTORY_SIZE);
        }
        recentHistory.add(round + who + "  " + result);
    }

    function pointsText(team as Number) as String {
        if (tieBreak) {
            return points[team].toString();
        }
        if (points[team] <= 2) {
            return labels[points[team]];
        }
        if (points[team] > 3 && points[team] > points[1 - team]) {
            return "AD";
        }
        return "40";
    }

    function server(initialServer as Number) as Number {
        var turns = completedGames;
        if (tieBreak && !gamesOnly) {
            // The opening server plays one point, then each team plays two.
            turns += (points[0] + points[1] + 1) / 2;
        }
        return (initialServer + turns) % 2;
    }

    private function applyEvent(team as Number, recordHistory as Boolean) as Void {
        if (gamesOnly) {
            applyGame(team, recordHistory);
        } else {
            applyPoint(team, recordHistory);
        }
    }

    private function applyPoint(team as Number, recordHistory as Boolean) as Void {
        if (gameRules.size() == completedGames) {
            gameRules.add(selectedRule);
        }
        var other = 1 - team;
        var decidingPoint = isDecidingPoint();
        points[team] += 1;
        var required = tieBreak ? 7 : 4;
        if (!decidingPoint && (points[team] < required || points[team] - points[other] < 2)) {
            if (recordHistory) {
                rememberEvent(team, pointsText(0) + "–" + pointsText(1));
            }
            return;
        }

        points = [0, 0];
        applyGame(team, recordHistory);
    }

    private function applyGame(team as Number, recordHistory as Boolean) as Void {
        games[team] += 1;
        completedGames += 1;
        var wonSet = gameLimit == 0 && (tieBreak || (games[team] >= 6 && games[team] - games[1 - team] >= 2));
        if (wonSet) {
            setScores.add(games[0].toString() + "-" + games[1].toString());
            sets[team] += 1;
            if (recordHistory) {
                var result = "Sets " + sets[0] + "–" + sets[1];
                if (gamesOnly) {
                    result = "Set " + games[0] + "–" + games[1] + " · " + result;
                }
                rememberEvent(team, result);
            }
            games = [0, 0];
            tieBreak = false;
            return;
        }
        if (gameLimit == 0) {
            tieBreak = games[0] == 6 && games[1] == 6;
        }
        if (recordHistory) {
            rememberEvent(team, PADEL_HISTORY_GAMES_PREFIX + games[0] + "–" + games[1]);
        }
    }
}
