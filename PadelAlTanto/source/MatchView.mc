import Toybox.Activity;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

enum MatchPage { HOME, READY, PLAYING, OPTIONS, SETTINGS, RULES, ROUND_OVER, ROUND_READY, MATCH_OVER, HISTORY, CONFIRM_SAVE, SAVE_FAILED, CONFIRM_EXIT, FINISHED, LANGUAGE }
enum PointVibration { RALLY_VIBRATION, GAME_VIBRATION, ROUND_VIBRATION, SET_VIBRATION, MATCH_VIBRATION }

class MatchView extends WatchUi.View {
    var page = HOME;
    var menuFocus = 0;
    var touchOn = true;
    var first = 0;
    var score as PadelScore;
    var recording;
    var height = 260;
    var resultIndex = 0;
    var ruleChoice = -1;
    var settingsLanguageFocused = false;
    var languageChoiceEnglish = false;
    var setupName as String = "";
    var nextFirst = 0;
    private var width = 260;
    private var automaticSetupName = false;
    private var languageSaveFailed = false;
    private var settingsReturn = HOME;
    private var saveReturn = PLAYING;
    private var historyReturn = PLAYING;
    private var previousHistoryAvailable as Boolean;
    private var timer;
    private var messageEs = "";
    private var messageEn = "";
    private var messageTicks = 0;
    private var advantageFont as Graphics.FontType = Graphics.FONT_LARGE;
    private var numberFonts as Array<Graphics.FontDefinition> = [
        Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD
    ];

    function initialize() {
        View.initialize();
        score = new PadelScore();
        score.configureBestOf(3);
        score.setRule(0);
        recording = new MatchRecording();
        previousHistoryAvailable = savedPointHistory().size() > 0;
        touchOn = Application.Storage.getValue("pointTouch") != false;
        var savedRule = Application.Storage.getValue("deuceRule");
        if (savedRule instanceof Number && savedRule >= -1 && savedRule <= 2) {
            score.setRule(savedRule);
        }
    }
    function onLayout(dc as Graphics.Dc) as Void {
        height = dc.getHeight();
        width = dc.getWidth();
        if (Graphics has :getVectorFont) {
            var font = Graphics.getVectorFont({ :face => "RobotoCondensedBold", :size => 68 });
            if (font != null) { advantageFont = font; }
        }
    }
    function onShow() as Void {
        applyTouchSetting();
    }
    function tick() as Void {
        if (messageTicks > 0) { messageTicks--; }
        WatchUi.requestUpdate();
    }
    function begin() {
        if (!recording.begin(score.gameLimit)) {
            flash("Error al iniciar", "Could not start");
            messageTicks = 3;
            return;
        }
        messageTicks = 0;
        page = PLAYING;
        applyTouchSetting();
        timer = new Timer.Timer();
        timer.start(method(:tick), 1000, true);
    }
    function applySetup(games as Number, bestOf as Number, rule as Number, name as String, gamesOnly as Boolean) as Void {
        if (page != HOME && page != READY) { return; }
        score.configureFormat(games);
        score.configureBestOf(bestOf);
        score.configureGamesOnly(gamesOnly);
        score.setRule(rule);
        setupName = name;
        automaticSetupName = false;
        page = READY;
        WatchUi.requestUpdate();
    }
    function applyTemplateSetup(games as Number, bestOf as Number, rule as Number, name as String, gamesOnly as Boolean) as Void {
        applySetup(games, bestOf, rule, name, gamesOnly);
        if (page == READY) { automaticSetupName = name.length() == 0; }
    }
    function menuItems() as Array<Symbol> {
        if (page == HOME) {
            return hasPreviousHistory() ? [:play, :templates, :settings, :history] : [:play, :templates, :settings];
        }
        return score.gamesOnly ? [:settings, :history, :finish] : [:settings, :rules, :history, :finish];
    }
    function activateMenu(index as Number) as Void {
        var items = menuItems();
        if (index < 0 || index >= items.size()) { return; }
        menuFocus = index;
        switch (items[index]) {
            case :play: page = READY; break;
            case :templates: openPadelSetup(self); break;
            case :settings: showSettings(); break;
            case :rules: showRules(); break;
            case :history: showHistory(); break;
            case :finish: confirmSave(PLAYING); break;
        }
    }
    function showSettings() {
        settingsReturn = page;
        settingsLanguageFocused = false;
        page = SETTINGS;
    }
    function closeSettings() {
        page = settingsReturn;
    }
    function activateSetting(language as Boolean) as Void {
        settingsLanguageFocused = language;
        if (language) {
            languageChoiceEnglish = PadelLanguage.isEnglish();
            languageSaveFailed = false;
            page = LANGUAGE;
        } else {
            toggleTouch();
        }
    }
    function selectLanguage(english as Boolean) as Void {
        try {
            PadelLanguage.setEnglish(english);
            page = SETTINGS;
        } catch (error instanceof Lang.StorageFullException) {
            languageSaveFailed = true;
        }
    }
    function hasPreviousHistory() as Boolean {
        return previousHistoryAvailable;
    }
    function showHistory() {
        if (page == HOME && !hasPreviousHistory()) { return; }
        historyReturn = page;
        page = HISTORY;
    }
    function closeHistory() {
        page = historyReturn;
    }
    function showRules() {
        if (score.gamesOnly) { return; }
        ruleChoice = score.selectedRule;
        page = RULES;
    }
    function moveRuleChoice(direction) {
        var next = ruleChoice + direction;
        if (next >= -1 && next <= 2) { ruleChoice = next; }
    }
    function applyRule() {
        if (score.selectedRule != ruleChoice) {
            setupName = "";
            automaticSetupName = false;
        }
        score.setRule(ruleChoice);
        Application.Storage.setValue("deuceRule", ruleChoice);
        page = OPTIONS;
    }
    function toggleTouch() {
        touchOn = !touchOn;
        applyTouchSetting();
        Application.Storage.setValue("pointTouch", touchOn);
    }
    private function applyTouchSetting() {
        if (WatchUi has :configureTouchEvents) {
            WatchUi.configureTouchEvents({ :enabled => touchOn });
        }
    }
    private function teamOnRow(top) {
        var serving = score.server(first);
        return top ? serving : 1 - serving;
    }
    function addScore(top) {
        if (page != PLAYING) { return; }
        var previousSets = score.setScores.size();
        var previousGames = score.games[0] + score.games[1];
        var team = teamOnRow(top);
        var scored = score.gamesOnly ? score.game(team) : score.point(team);
        if (!scored) { return; }
        messageTicks = 0;
        showCompletion();
        if (page == MATCH_OVER) { vibratePoint(MATCH_VIBRATION); }
        else if (page == ROUND_OVER) { vibratePoint(ROUND_VIBRATION); }
        else if (score.setScores.size() > previousSets) { vibratePoint(SET_VIBRATION); }
        else if (score.games[0] + score.games[1] > previousGames) { vibratePoint(GAME_VIBRATION); }
        else { vibratePoint(RALLY_VIBRATION); }
    }
    function subtractScore(top) {
        if (page != PLAYING) { return; }
        var team = teamOnRow(top);
        if (score.gamesOnly) {
            if (score.removeLastGameFor(team)) { flash("Juego restado", "Game removed"); }
            else { flash("Sin juego que restar", "No game to remove"); }
        } else {
            if (score.removeLastPointFor(team)) { flash("Punto restado", "Point removed"); }
            else { flash("Sin punto que restar", "No point to remove"); }
        }
        showCompletion();
    }
    private function showCompletion() {
        if (score.roundComplete()) { page = ROUND_OVER; }
        else if (score.matchComplete()) { page = MATCH_OVER; }
    }
    function vibratePoint(pattern as Number) as Void {
        if (!(Attention has :vibrate)) { return; }
        if (pattern == RALLY_VIBRATION) {
            Attention.vibrate([new Attention.VibeProfile(65, 60)]);
        } else if (pattern == GAME_VIBRATION) {
            Attention.vibrate([new Attention.VibeProfile(80, 155)]);
        } else if (pattern == ROUND_VIBRATION) {
            Attention.vibrate([new Attention.VibeProfile(90, 120), new Attention.VibeProfile(0, 90),
                new Attention.VibeProfile(90, 120)]);
        } else if (pattern == SET_VIBRATION) {
            Attention.vibrate([new Attention.VibeProfile(85, 85), new Attention.VibeProfile(0, 90),
                new Attention.VibeProfile(95, 220)]);
        } else {
            Attention.vibrate([new Attention.VibeProfile(100, 175), new Attention.VibeProfile(0, 90),
                new Attention.VibeProfile(100, 175), new Attention.VibeProfile(0, 90),
                new Attention.VibeProfile(100, 240)]);
        }
    }
    function undo() {
        if (score.undo()) {
            if (page == ROUND_OVER || page == MATCH_OVER) { page = PLAYING; }
            if (score.gamesOnly) { flash("Juego deshecho", "Game undone"); }
            else { flash("Punto deshecho", "Point undone"); }
        } else {
            if (score.gamesOnly) { flash("Aún no hay juegos", "No games yet"); }
            else { flash("Aún no hay puntos", "No points yet"); }
        }
    }
    private function flash(es as String, en as String) as Void {
        messageEs = es;
        messageEn = en;
        messageTicks = 2;
    }
    function prepareNextRound() {
        nextFirst = 0;
        page = ROUND_READY;
    }
    function startNextRound() {
        if (score.nextRound()) {
            first = nextFirst;
            page = PLAYING;
            messageTicks = 0;
        }
    }
    function confirmSave(returnPage) {
        saveReturn = returnPage;
        page = CONFIRM_SAVE;
    }
    function cancelSave() {
        page = saveReturn;
    }
    function resultCount() {
        if (score.gameLimit == 0) { return score.setScores.size(); }
        var archived = score.completedRounds.size();
        return archived + (archived == 0 || hasCurrentResult(score) ? 1 : 0);
    }
    function finish() {
        if (recording.save(score)) {
            page = FINISHED;
            resultIndex = resultCount();
            stopTimer();
        } else {
            page = SAVE_FAILED;
        }
    }
    private function stopTimer() {
        if (timer != null) {
            timer.stop();
            timer = null;
        }
    }
    function shutdown() {
        stopTimer();
        if (recording.session != null) { recording.save(score); }
        recording.strokes.stop();
    }
    function yAt(percent) { return height * percent / 100; }
    function upperEdge() { return yAt(16); }
    function divider() { return yAt(50); }
    function lowerEdge() { return yAt(83); }
    function menuY(index) { return yAt(32 + index * 15); }
    function settingY(language as Boolean) { return yAt(language ? 65 : 45); }
    function languageY(english as Boolean) { return yAt(english ? 57 : 34); }
    function ruleY(rule) { return yAt(31 + (rule + 1) * 11); }
    function roundActionY(index) {
        if (index < 2) { return yAt(59 + index * 14); }
        return yAt(index == 2 ? 83 : 92);
    }
    function nextRoundStartY() { return yAt(86); }
    function pointY(top) { return top ? yAt(33) : yAt(67); }
    function subtractX() { return width * 14 / 100; }
    function addTouchLeft() { return subtractX() + yAt(10); }
    function historyFoot(x) { return x < width / 2; }
    function hitRow(y, middle) { return y >= middle - yAt(5) && y < middle + yAt(5); }
    function hitsScore(y) {
        var margin = yAt(3);
        return y >= upperEdge() && y < lowerEdge() &&
            (y < divider() - margin || y > divider() + margin);
    }
    function hitsSubtract(x, y) {
        var dx = x - subtractX();
        var dy = y - pointY(y < divider());
        var radius = yAt(7);
        return dx * dx + dy * dy <= radius * radius;
    }
    private function textAt(dc, x, y, font, text, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    private function center(dc, y, font, text, color) {
        textAt(dc, dc.getWidth()/2, y, font, text, color);
    }
    private function scoreFont(dc as Graphics.Dc, tally as String) as Graphics.FontType {
        if (tally.equals("AD")) { return advantageFont; }
        for (var i = 0; i < numberFonts.size(); i += 1) {
            var font = numberFonts[i];
            if (dc.getFontHeight(font) <= yAt(44) && dc.getTextWidthInPixels(tally, font) <= width * 36 / 100) {
                return font;
            }
        }
        return Graphics.FONT_LARGE;
    }
    private function row(dc, team, top) {
        var y = pointY(top);
        var infoX = width * 73 / 100;
        var ink = top ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
        var who = team == 0 ? tr("NOSOTROS", "US") : tr("RIVALES", "OPPONENTS");
        if (touchOn) {
            var x = subtractX();
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(x, y, yAt(5));
            dc.drawLine(x - 5, y, x + 5, y);
        }
        if (top) { textAt(dc, infoX, y - yAt(14), Graphics.FONT_XTINY, tr("SAQUE", "SERVE"), ink); }
        var tally = score.gamesOnly ? score.games[team].toString() : score.pointsText(team);
        textAt(dc, width * 39 / 100, y, scoreFont(dc, tally), tally, ink);
        textAt(dc, infoX, y - yAt(6), Graphics.FONT_XTINY, who, ink);
        if (!score.gamesOnly) {
            var gamesY = y + yAt(score.gameLimit > 0 ? 6 : 2);
            textAt(dc, infoX, gamesY, Graphics.FONT_XTINY, tr("Juegos ", "Games ") + score.games[team], Graphics.COLOR_WHITE);
        }
        if (score.gameLimit == 0) {
            var setsY = y + yAt(score.gamesOnly ? 5 : 10);
            textAt(dc, infoX, setsY, Graphics.FONT_XTINY, "Sets " + score.sets[team], Graphics.COLOR_WHITE);
        }
    }
    private function drawPlay(dc) {
        var white = Graphics.COLOR_WHITE;
        var accent = Graphics.COLOR_YELLOW;
        var info = Activity.getActivityInfo();
        var bpm = info != null && info.currentHeartRate != null ? info.currentHeartRate.toString() : "--";
        var strokes = recording.strokes.available ? recording.strokes.count.toString() : "--";
        center(dc, yAt(10), Graphics.FONT_XTINY,
            bpm + tr(" lpm  ·  ~", " bpm  ·  ~") + strokes + tr(" golpes", " hits"), white);
        var serving = score.server(first);
        row(dc, serving, true);
        var deciding = !score.gamesOnly && score.isDecidingPoint();
        var decidingLabel = tr("PUNTO DECISIVO", "DECIDING POINT");
        if (score.gameLimit > 0) {
            var status = deciding ? decidingLabel : tr("Ronda ", "Round ") + roundNumber();
            var progress = (score.games[0] + score.games[1]) + "/" + score.gameLimit;
            center(dc, divider(), Graphics.FONT_XTINY, status + " · " + progress + (score.gamesOnly ? tr(" juegos", " games") : ""), accent);
        } else if (score.tieBreak) {
            center(dc, divider(), Graphics.FONT_XTINY,
                score.gamesOnly ? tr("Desempate · anota el ganador", "Tiebreak · score the winner") : tr("DESEMPATE", "TIEBREAK"), accent);
        } else if (score.gamesOnly || deciding) {
            center(dc, divider(), Graphics.FONT_XTINY,
                score.gamesOnly ? tr("JUEGOS · MARCA AL GANADOR", "GAMES · SCORE THE WINNER") : decidingLabel, accent);
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(yAt(8), divider(), dc.getWidth() - yAt(8), divider());
        }
        row(dc, 1 - serving, false);
        var hint = touchOn ? tr("Táctil sí · (-) resta", "Touch on · (-) subtract") : tr("Táctil no · BACK deshace", "Touch off · BACK undoes");
        if (score.gamesOnly && touchOn) { hint = tr("Táctil sí · (-) quita juego", "Touch on · (-) remove game"); }
        center(dc, yAt(84), Graphics.FONT_XTINY, messageTicks > 0 ? tr(messageEs, messageEn) : hint, white);
        textAt(dc, width * 37 / 100, yAt(91), Graphics.FONT_XTINY, tr("Historial", "History"), accent);
        textAt(dc, width * 63 / 100, yAt(91), Graphics.FONT_XTINY, tr("Menú", "Menu"), accent);
    }
    private function formatName() {
        if (score.gameLimit > 0) {
            return "Americano · " + score.gameLimit + (score.gameLimit == 1 ? tr(" juego", " game") : tr(" juegos", " games"));
        }
        if (score.bestOf == 0) { return tr("Partido normal · libre", "Standard match · open"); }
        return tr("Mejor de ", "Best of ") + score.bestOf + (score.bestOf == 1 ? " set" : " sets");
    }
    private function roundNumber() {
        return score.completedRounds.size() + 1;
    }
    private function setupTitle(dc) {
        if (!automaticSetupName && setupName.length() == 0) { return tr("Formato del partido", "Match format"); }
        var label = automaticSetupName ? padelFormatLabel(score.gameLimit, score.bestOf) : setupName;
        var suffix = "";
        while (label.length() > 0 && dc.getTextWidthInPixels(label + suffix, Graphics.FONT_XTINY) > width * 9 / 10) {
            label = label.substring(0, label.length() - 1);
            suffix = "…";
        }
        return label + suffix;
    }
    private function drawReady(dc) {
        var white = Graphics.COLOR_WHITE;
        var accent = Graphics.COLOR_YELLOW;
        center(dc, yAt(15), Graphics.FONT_SMALL, tr("Primer saque", "First serve"), accent);
        drawServingChoice(dc, first, yAt(27), yAt(39));
        center(dc, yAt(49), Graphics.FONT_XTINY, setupTitle(dc), accent);
        center(dc, yAt(57), Graphics.FONT_XTINY, formatName(), white);
        var tracking = score.gamesOnly ? tr("Anotar · Solo juegos", "Scoring · Games only") : tr("Regla · ", "Rule · ") + padelRuleLabel(score.selectedRule);
        center(dc, yAt(66), Graphics.FONT_XTINY, tracking, white);
        center(dc, yAt(75), Graphics.FONT_XTINY, messageTicks > 0 ? tr(messageEs, messageEn) : tr("START   Iniciar", "START   Begin"), white);
        center(dc, yAt(86), Graphics.FONT_XTINY, tr("BACK   Inicio", "BACK   Home"), accent);
    }
    private function drawServingChoice(dc, selected, usY, themY) {
        var white = Graphics.COLOR_WHITE;
        var accent = Graphics.COLOR_YELLOW;
        center(dc, usY, Graphics.FONT_SMALL, (selected == 0 ? "› " : "") + tr("UP  Nosotros", "UP  Us"), selected == 0 ? accent : white);
        center(dc, themY, Graphics.FONT_SMALL, (selected == 1 ? "› " : "") + tr("DOWN  Rivales", "DOWN  Opponents"), selected == 1 ? accent : white);
    }
    private function menuLabel(action as Symbol) as String {
        switch (action) {
            case :play: return tr("Jugar", "Play");
            case :templates: return tr("Plantillas", "Templates");
            case :settings: return tr("Ajustes", "Settings");
            case :rules: return tr("Regla en iguales", "Deuce rule");
            case :history: return page == HOME ? tr("Última sesión", "Last session") : tr("Historial", "History");
            default: return tr("Terminar partido", "End match");
        }
    }
    private function drawMenu(dc) {
        center(dc, yAt(16), Graphics.FONT_SMALL,
            page == HOME ? Application.loadResource(Rez.Strings.AppName) : tr("Partido", "Match"), Graphics.COLOR_YELLOW);
        var items = menuItems();
        for (var i = 0; i < items.size(); i++) {
            var y = menuY(i);
            if (i == menuFocus) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(width * 14 / 100, y - yAt(6), width * 72 / 100, yAt(12), yAt(4));
            }
            center(dc, y, Graphics.FONT_TINY, menuLabel(items[i]), i == menuFocus ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE);
        }
        center(dc, yAt(89), Graphics.FONT_XTINY, tr("START   Elegir", "START   Select"), Graphics.COLOR_LT_GRAY);
    }
    private function drawSettings(dc) {
        var white = Graphics.COLOR_WHITE;
        var accent = Graphics.COLOR_YELLOW;
        center(dc, yAt(17), Graphics.FONT_SMALL, tr("Ajustes", "Settings"), accent);
        var touchSetting = touchOn ? tr("Pantalla táctil · Sí", "Touchscreen · On") : tr("Pantalla táctil · No", "Touchscreen · Off");
        var languageSetting = tr("Idioma · ", "Language · ") + languageName(PadelLanguage.isEnglish());
        center(dc, settingY(false), Graphics.FONT_TINY,
            (settingsLanguageFocused ? "" : "› ") + touchSetting, settingsLanguageFocused ? white : accent);
        center(dc, settingY(true), Graphics.FONT_TINY,
            (settingsLanguageFocused ? "› " : "") + languageSetting, settingsLanguageFocused ? accent : white);
        center(dc, yAt(76), Graphics.FONT_XTINY, tr("START   Elegir", "START   Select"), white);
        center(dc, yAt(86), Graphics.FONT_XTINY, tr("BACK   Volver", "BACK   Return"), white);
    }
    private function languageName(english as Boolean) as String {
        return english ? "English" : "Español";
    }
    private function drawLanguage(dc) {
        var white = Graphics.COLOR_WHITE;
        var accent = Graphics.COLOR_YELLOW;
        center(dc, yAt(17), Graphics.FONT_SMALL, tr("Idioma", "Language"), accent);
        center(dc, languageY(false), Graphics.FONT_SMALL,
            (languageChoiceEnglish ? "" : "› ") + languageName(false), languageChoiceEnglish ? white : accent);
        center(dc, languageY(true), Graphics.FONT_SMALL,
            (languageChoiceEnglish ? "› " : "") + languageName(true), languageChoiceEnglish ? accent : white);
        var action = languageSaveFailed ? tr("Sin espacio · START reintenta", "Storage full · START retries") : tr("START   Aplicar", "START   Apply");
        center(dc, yAt(76), Graphics.FONT_XTINY, action, white);
        center(dc, yAt(86), Graphics.FONT_XTINY, tr("BACK   Volver", "BACK   Return"), white);
    }
    private function drawRules(dc) {
        var white = Graphics.COLOR_WHITE;
        var accent = Graphics.COLOR_YELLOW;
        center(dc, yAt(19), Graphics.FONT_SMALL, tr("Regla en iguales", "Deuce rule"), accent);
        for (var rule = -1; rule <= 2; rule += 1) {
            var selected = rule == ruleChoice;
            center(dc, ruleY(rule), Graphics.FONT_TINY, (selected ? "› " : "") + padelRuleLabel(rule), selected ? accent : white);
        }
        center(dc, yAt(77), Graphics.FONT_XTINY, tr("START   Aplicar", "START   Apply"), white);
        center(dc, yAt(86), Graphics.FONT_XTINY, tr("BACK   Volver", "BACK   Return"), white);
    }
    private function drawCompletion(dc) {
        var white = Graphics.COLOR_WHITE;
        var accent = Graphics.COLOR_YELLOW;
        var round = page == ROUND_OVER;
        var result = round ? score.games : score.sets;
        var title = round ? tr("Ronda ", "Round ") + roundNumber() + tr(" cerrada", " complete") :
            tr("Partido terminado", "Match complete");
        center(dc, yAt(17), Graphics.FONT_SMALL, title, accent);
        center(dc, yAt(30), Graphics.FONT_XTINY, tr("Nosotros  /  Rivales", "Us  /  Opponents"), white);
        center(dc, yAt(44), Graphics.FONT_LARGE, result[0] + " - " + result[1], white);
        center(dc, roundActionY(0), Graphics.FONT_XTINY,
            round ? tr("START   Nueva ronda", "START   New round") : tr("START   Guardar partido", "START   Save match"), accent);
        if (round) { center(dc, roundActionY(1), Graphics.FONT_XTINY, tr("DOWN   Guardar sesión", "DOWN   Save session"), white); }
        center(dc, roundActionY(round ? 3 : 1), Graphics.FONT_XTINY, tr("UP   Historial", "UP   History"), accent);
        center(dc, roundActionY(2), Graphics.FONT_XTINY,
            score.gamesOnly ? tr("BACK   Deshacer juego", "BACK   Undo game") : tr("BACK   Deshacer punto", "BACK   Undo point"), white);
    }
    private function drawHistory(dc) {
        var white = Graphics.COLOR_WHITE;
        var previous = historyReturn == HOME;
        var gamesOnly = previous ? savedHistoryUsesGames() : score.gamesOnly;
        var lines = previous ? savedPointHistory() : score.recentPointLines();
        var title = gamesOnly ? tr("Últimos juegos", "Recent games") :
            (previous ? tr("Última sesión", "Last session") : tr("Últimos puntos", "Recent points"));
        center(dc, yAt(15), Graphics.FONT_SMALL, title, Graphics.COLOR_YELLOW);
        center(dc, yAt(26), Graphics.FONT_XTINY, tr("Nosotros  /  Rivales", "Us  /  Opponents"), white);
        for (var i = 0; i < lines.size(); i += 1) {
            center(dc, yAt(36 + i * 10), Graphics.FONT_XTINY, lines[i], white);
        }
        if (lines.size() == 0) {
            center(dc, yAt(51), Graphics.FONT_TINY, gamesOnly ? tr("Aún no hay juegos", "No games yet") : tr("Aún no hay puntos", "No points yet"), white);
        }
        center(dc, yAt(88), Graphics.FONT_XTINY, tr("BACK   Volver", "BACK   Return"), Graphics.COLOR_YELLOW);
    }
    private function drawNextRound(dc) {
        var white = Graphics.COLOR_WHITE;
        var accent = Graphics.COLOR_YELLOW;
        center(dc, yAt(18), Graphics.FONT_SMALL, tr("Ronda ", "Round ") + (roundNumber() + 1), accent);
        center(dc, yAt(32), Graphics.FONT_XTINY, tr("Primer saque", "First serve"), white);
        drawServingChoice(dc, nextFirst, yAt(46), yAt(61));
        center(dc, yAt(73), Graphics.FONT_XTINY, tr("BACK   Volver", "BACK   Return"), white);
        center(dc, nextRoundStartY(), Graphics.FONT_XTINY, tr("START   Jugar ronda", "START   Play round"), accent);
    }
    private function americanoResult() {
        var archived = score.completedRounds.size();
        if (resultIndex == resultCount()) {
            return tr("Rondas completas ", "Completed rounds ") + (archived + (score.roundComplete() ? 1 : 0));
        }
        var partial = resultIndex < archived ? score.completedRounds[resultIndex] : score.games[0] + "-" + score.games[1];
        return tr("Ronda ", "Round ") + (resultIndex + 1) + "   " + partial;
    }
    private function drawsIncompleteRound() {
        return score.gameLimit > 0 && resultIndex == score.completedRounds.size() &&
            resultIndex < resultCount() && !score.roundComplete();
    }
    private function drawFinished(dc) {
        var white = Graphics.COLOR_WHITE;
        var accent = Graphics.COLOR_YELLOW;
        var americano = score.gameLimit > 0;
        center(dc, yAt(21), Graphics.FONT_XTINY, americano ? tr("Sesión guardada", "Session saved") : tr("Partido guardado", "Match saved"), accent);
        center(dc, yAt(33), Graphics.FONT_XTINY, tr("Nosotros  /  Rivales", "Us  /  Opponents"), white);
        var line;
        if (americano) { line = americanoResult(); }
        else if (resultIndex == resultCount()) { line = "Sets   " + score.sets[0] + " - " + score.sets[1]; }
        else { line = "Set " + (resultIndex + 1) + "   " + score.setScores[resultIndex]; }
        center(dc, yAt(48), americano ? Graphics.FONT_TINY : Graphics.FONT_SMALL, line, white);
        var strokes = recording.strokes.available ? "~" + recording.strokes.count + tr(" golpes", " hits") : tr("Golpes sin datos", "No hit data");
        center(dc, yAt(62), Graphics.FONT_XTINY, drawsIncompleteRound() ? tr("Ronda incompleta", "Incomplete round") : strokes, white);
        center(dc, yAt(73), Graphics.FONT_XTINY, tr("UP / DOWN   Parciales", "UP / DOWN   Results"), white);
        center(dc, yAt(83), Graphics.FONT_XTINY, tr("START   Historial", "START   History"), accent);
        center(dc, yAt(92), Graphics.FONT_XTINY, tr("BACK   Salir", "BACK   Exit"), white);
    }
    function onUpdate(dc) {
        height = dc.getHeight();
        width = dc.getWidth();
        var h = height;
        var white = Graphics.COLOR_WHITE;
        var accent = Graphics.COLOR_YELLOW;
        dc.setColor(white, Graphics.COLOR_BLACK);
        dc.clear();
        if (page == PLAYING) {
            drawPlay(dc);
        } else if (page == READY) {
            drawReady(dc);
        } else if (page == HOME || page == OPTIONS) {
            drawMenu(dc);
        } else if (page == SETTINGS) {
            drawSettings(dc);
        } else if (page == LANGUAGE) {
            drawLanguage(dc);
        } else if (page == RULES) {
            drawRules(dc);
        } else if (page == ROUND_OVER || page == MATCH_OVER) {
            drawCompletion(dc);
        } else if (page == ROUND_READY) {
            drawNextRound(dc);
        } else if (page == HISTORY) {
            drawHistory(dc);
        } else if (page == CONFIRM_SAVE || page == SAVE_FAILED) {
            center(dc, h*31/100, Graphics.FONT_SMALL,
                page == CONFIRM_SAVE ? tr("¿Terminar?", "Finish?") : tr("Error al guardar", "Could not save"), accent);
            center(dc, h*51/100, Graphics.FONT_XTINY,
                page == CONFIRM_SAVE ? tr("START   Guardar", "START   Save") : tr("START   Reintentar", "START   Retry"), white);
            var backLabel = saveReturn == PLAYING ? tr("BACK   Seguir jugando", "BACK   Keep playing") : tr("BACK   Volver", "BACK   Return");
            center(dc, h*67/100, Graphics.FONT_XTINY, page == CONFIRM_SAVE ? backLabel : tr("BACK   Salir…", "BACK   Exit…"), white);
        } else if (page == CONFIRM_EXIT) {
            center(dc, h*32/100, Graphics.FONT_SMALL, tr("¿Salir ahora?", "Exit now?"), accent);
            center(dc, h*52/100, Graphics.FONT_XTINY, tr("START   Salir", "START   Exit"), white);
            center(dc, h*67/100, Graphics.FONT_XTINY, tr("BACK   Reintentar", "BACK   Retry"), white);
        } else {
            drawFinished(dc);
        }
    }
}

class MatchInput extends WatchUi.InputDelegate {
    private var view;
    function initialize(v) {
        InputDelegate.initialize();
        view = v;
    }
    function onKey(evt) {
        return handleKey(evt.getKey());
    }
    function handleKey(k) {
        if (view.page == HOME || view.page == OPTIONS) {
            if (k == WatchUi.KEY_UP && view.menuFocus > 0) { view.menuFocus--; }
            else if (k == WatchUi.KEY_DOWN && view.menuFocus + 1 < view.menuItems().size()) { view.menuFocus++; }
            else if (k == WatchUi.KEY_ENTER) { view.activateMenu(view.menuFocus); }
            else if (k == WatchUi.KEY_MENU) { view.showSettings(); }
            else if (k == WatchUi.KEY_ESC) {
                if (view.page == HOME) { System.exit(); }
                else { view.page = PLAYING; }
            }
        } else if (view.page == READY) {
            if (k == WatchUi.KEY_UP) { view.first = 0; }
            else if (k == WatchUi.KEY_DOWN) { view.first = 1; }
            else if (k == WatchUi.KEY_ENTER) { view.begin(); }
            else if (k == WatchUi.KEY_MENU) { view.showSettings(); }
            else if (k == WatchUi.KEY_ESC) { view.page = HOME; view.menuFocus = 0; }
        } else if (view.page == PLAYING) {
            if (k == WatchUi.KEY_UP || k == WatchUi.KEY_DOWN) { view.addScore(k == WatchUi.KEY_UP); }
            else if (k == WatchUi.KEY_ESC) { view.undo(); }
            else if (k == WatchUi.KEY_ENTER) { view.page = OPTIONS; view.menuFocus = 0; }
            else if (k == WatchUi.KEY_MENU) { view.showSettings(); }
        } else if (view.page == SETTINGS) {
            if (k == WatchUi.KEY_UP || k == WatchUi.KEY_DOWN) { view.settingsLanguageFocused = k == WatchUi.KEY_DOWN; }
            else if (k == WatchUi.KEY_ENTER) { view.activateSetting(view.settingsLanguageFocused); }
            else if (k == WatchUi.KEY_ESC) { view.closeSettings(); }
        } else if (view.page == LANGUAGE) {
            if (k == WatchUi.KEY_UP || k == WatchUi.KEY_DOWN) { view.languageChoiceEnglish = k == WatchUi.KEY_DOWN; }
            else if (k == WatchUi.KEY_ENTER) { view.selectLanguage(view.languageChoiceEnglish); }
            else if (k == WatchUi.KEY_ESC) { view.page = SETTINGS; }
        } else if (view.page == RULES) {
            if (k == WatchUi.KEY_UP) { view.moveRuleChoice(-1); }
            else if (k == WatchUi.KEY_DOWN) { view.moveRuleChoice(1); }
            else if (k == WatchUi.KEY_ENTER) { view.applyRule(); }
            else if (k == WatchUi.KEY_ESC) { view.page = OPTIONS; }
        } else if (view.page == ROUND_OVER || view.page == MATCH_OVER) {
            if (k == WatchUi.KEY_ENTER) {
                if (view.page == ROUND_OVER) { view.prepareNextRound(); }
                else { view.confirmSave(MATCH_OVER); }
            }
            else if (k == WatchUi.KEY_DOWN && view.page == ROUND_OVER) { view.confirmSave(ROUND_OVER); }
            else if (k == WatchUi.KEY_UP || k == WatchUi.KEY_MENU) { view.showHistory(); }
            else if (k == WatchUi.KEY_ESC) { view.undo(); }
        } else if (view.page == ROUND_READY) {
            if (k == WatchUi.KEY_UP) { view.nextFirst = 0; }
            else if (k == WatchUi.KEY_DOWN) { view.nextFirst = 1; }
            else if (k == WatchUi.KEY_ENTER) { view.startNextRound(); }
            else if (k == WatchUi.KEY_ESC) { view.page = ROUND_OVER; }
        } else if (view.page == HISTORY) {
            if (k == WatchUi.KEY_ESC) { view.closeHistory(); }
        } else if (view.page == CONFIRM_SAVE || view.page == SAVE_FAILED) {
            if (k == WatchUi.KEY_ENTER) { view.finish(); }
            else if (k == WatchUi.KEY_ESC) {
                if (view.page == CONFIRM_SAVE) { view.cancelSave(); }
                else { view.page = CONFIRM_EXIT; }
            }
        } else if (view.page == CONFIRM_EXIT) {
            if (k == WatchUi.KEY_ENTER) { System.exit(); }
            else if (k == WatchUi.KEY_ESC) { view.page = SAVE_FAILED; }
        } else if (view.page == FINISHED) {
            if (k == WatchUi.KEY_ESC) { System.exit(); }
            else if (k == WatchUi.KEY_ENTER || k == WatchUi.KEY_MENU) { view.showHistory(); }
            else if (k == WatchUi.KEY_UP && view.resultIndex > 0) { view.resultIndex--; }
            else if (k == WatchUi.KEY_DOWN && view.resultIndex < view.resultCount()) { view.resultIndex++; }
        }
        WatchUi.requestUpdate();
        return true;
    }
    function onTap(evt) {
        var point = evt.getCoordinates();
        return tapAt(point[0], point[1]);
    }
    function tapAt(x, y) {
        if (!view.touchOn) { return true; }
        if (view.page == PLAYING) {
            if (view.hitsScore(y)) {
                var top = y < view.divider();
                if (view.hitsSubtract(x, y)) { view.subtractScore(top); }
                else if (x >= view.addTouchLeft()) { view.addScore(top); }
                WatchUi.requestUpdate();
            } else if (y >= view.yAt(89)) {
                if (view.historyFoot(x)) {
                    view.showHistory();
                    WatchUi.requestUpdate();
                } else {
                    return handleKey(WatchUi.KEY_ENTER);
                }
            }
        } else if (view.page == READY) {
            if (view.hitRow(y, view.yAt(27))) { return handleKey(WatchUi.KEY_UP); }
            if (view.hitRow(y, view.yAt(39))) { return handleKey(WatchUi.KEY_DOWN); }
            if (view.hitRow(y, view.yAt(75))) { return handleKey(WatchUi.KEY_ENTER); }
            if (view.hitRow(y, view.yAt(86))) { return handleKey(WatchUi.KEY_ESC); }
        } else if (view.page == HOME || view.page == OPTIONS) {
            if (view.hitRow(y, view.yAt(89))) { return handleKey(WatchUi.KEY_ENTER); }
            var count = view.menuItems().size();
            for (var i = 0; i < count; i++) {
                if ((y - view.menuY(i)).abs() <= view.yAt(7)) {
                    view.activateMenu(i);
                    WatchUi.requestUpdate();
                    return true;
                }
            }
        } else if (view.page == SETTINGS) {
            if (view.hitRow(y, view.settingY(false))) {
                view.settingsLanguageFocused = false;
                return handleKey(WatchUi.KEY_ENTER);
            }
            if (view.hitRow(y, view.settingY(true))) {
                view.settingsLanguageFocused = true;
                return handleKey(WatchUi.KEY_ENTER);
            }
            if (view.hitRow(y, view.yAt(76))) { return handleKey(WatchUi.KEY_ENTER); }
            if (view.hitRow(y, view.yAt(86))) { return handleKey(WatchUi.KEY_ESC); }
        } else if (view.page == LANGUAGE) {
            if (view.hitRow(y, view.languageY(false))) {
                view.languageChoiceEnglish = false;
                return handleKey(WatchUi.KEY_ENTER);
            }
            if (view.hitRow(y, view.languageY(true))) {
                view.languageChoiceEnglish = true;
                return handleKey(WatchUi.KEY_ENTER);
            }
            if (view.hitRow(y, view.yAt(76))) { return handleKey(WatchUi.KEY_ENTER); }
            if (view.hitRow(y, view.yAt(86))) { return handleKey(WatchUi.KEY_ESC); }
        } else if (view.page == RULES) {
            for (var rule = -1; rule <= 2; rule += 1) {
                if (view.hitRow(y, view.ruleY(rule))) {
                    view.ruleChoice = rule;
                    WatchUi.requestUpdate();
                    return true;
                }
            }
            if (view.hitRow(y, view.yAt(77))) { return handleKey(WatchUi.KEY_ENTER); }
            if (view.hitRow(y, view.yAt(86))) { return handleKey(WatchUi.KEY_ESC); }
        } else if (view.page == ROUND_OVER || view.page == MATCH_OVER) {
            if (view.hitRow(y, view.roundActionY(0))) { return handleKey(WatchUi.KEY_ENTER); }
            if (view.hitRow(y, view.roundActionY(1))) {
                return handleKey(view.page == ROUND_OVER ? WatchUi.KEY_DOWN : WatchUi.KEY_UP);
            }
            if (view.hitRow(y, view.roundActionY(2))) { return handleKey(WatchUi.KEY_ESC); }
            if (view.page == ROUND_OVER && view.hitRow(y, view.roundActionY(3))) { return handleKey(WatchUi.KEY_UP); }
        } else if (view.page == ROUND_READY) {
            if (view.hitRow(y, view.yAt(46))) { return handleKey(WatchUi.KEY_UP); }
            if (view.hitRow(y, view.yAt(61))) { return handleKey(WatchUi.KEY_DOWN); }
            if (view.hitRow(y, view.yAt(73))) { return handleKey(WatchUi.KEY_ESC); }
            // A repeat of the confirmation tap stays out of both score rows and the options target.
            if (y >= view.lowerEdge() && y < view.yAt(89)) { return handleKey(WatchUi.KEY_ENTER); }
        } else if (view.page == HISTORY) {
            if (view.hitRow(y, view.yAt(88))) { return handleKey(WatchUi.KEY_ESC); }
        } else if (view.page == FINISHED) {
            if (view.hitRow(y, view.yAt(73))) {
                view.resultIndex = (view.resultIndex + 1) % (view.resultCount() + 1);
                WatchUi.requestUpdate();
            }
            if (view.hitRow(y, view.yAt(83))) { return handleKey(WatchUi.KEY_ENTER); }
            if (view.hitRow(y, view.yAt(92))) { return handleKey(WatchUi.KEY_ESC); }
        } else {
            var confirmY = view.page == CONFIRM_EXIT ? 52 : 51;
            if (view.hitRow(y, view.yAt(confirmY))) { return handleKey(WatchUi.KEY_ENTER); }
            if (view.hitRow(y, view.yAt(67))) { return handleKey(WatchUi.KEY_ESC); }
        }
        return true;
    }
    function onHold(evt) {
        return true;
    }
    function onRelease(evt) {
        // Garmin sends this after a hold; short touches go through onTap.
        return true;
    }
    function swipeDirection(direction) {
        if (!view.touchOn) { return true; }
        if (direction == WatchUi.SWIPE_LEFT || direction == WatchUi.SWIPE_RIGHT) {
            return handleKey(WatchUi.KEY_ESC);
        }
        if (view.page == HOME || view.page == OPTIONS || view.page == RULES || view.page == SETTINGS || view.page == LANGUAGE) {
            if (direction == WatchUi.SWIPE_UP) { return handleKey(WatchUi.KEY_DOWN); }
            if (direction == WatchUi.SWIPE_DOWN) { return handleKey(WatchUi.KEY_UP); }
        }
        return true;
    }
    function onSwipe(evt) {
        return swipeDirection(evt.getDirection());
    }
}
