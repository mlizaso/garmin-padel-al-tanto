import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

const PADEL_TEMPLATES_KEY = "padelTemplates";
const PADEL_MAX_ROUND_GAMES = 99;

function padelRuleLabel(rule as Number) as String {
    if (rule < 0) { return tr("Ventaja", "Advantage"); }
    if (rule == 0) { return tr("Punto de oro", "Golden point"); }
    return tr("Oro tras ", "Gold after ") + rule + (rule == 1 ? tr(" ventaja", " advantage") : tr(" ventajas", " advantages"));
}

function padelSetFormat(bestOf as Number) as String {
    return bestOf == 0 ? tr("Sets sin límite", "Unlimited sets") : tr("Mejor de ", "Best of ") + bestOf;
}

function padelFormatLabel(games as Number, bestOf as Number) as String {
    return games > 0 ? "Americano " + games : padelSetFormat(bestOf);
}

function padelScoringLabel(gamesOnly as Boolean) as String {
    return gamesOnly ? tr("Solo juegos", "Games only") : tr("Cada punto", "Every point");
}

class PadelTemplate {
    var name as String;
    var games as Number;
    var bestOf as Number;
    var rule as Number;
    var gamesOnly as Boolean;

    function initialize(templateName as String, roundGames as Number, matchSets as Number,
        deuceRule as Number, countGamesOnly as Boolean) {
        name = templateName;
        games = roundGames;
        bestOf = matchSets;
        rule = deuceRule;
        gamesOnly = countGamesOnly;
    }

    function formatLabel() as String {
        return padelFormatLabel(games, bestOf);
    }

    function label() as String {
        return name.length() == 0 ? formatLabel() : name;
    }

    function nameLabel() as String {
        return name.length() == 0 ? tr("Automático", "Automatic") : name;
    }

    function scoringLabel() as String {
        return padelScoringLabel(gamesOnly);
    }

    function scoringSummary() as String {
        return gamesOnly ? scoringLabel() : padelRuleLabel(rule);
    }
}

class PadelTemplateLibrary {
    private var entries as Array<PadelTemplate> = [];

    function initialize() {
        var stored = Storage.getValue(PADEL_TEMPLATES_KEY);
        // An empty saved list is distinct from the first launch of this menu.
        if (stored == null) {
            entries = [
                new PadelTemplate("", 0, 3, 0, false),
                new PadelTemplate("", 7, 0, 0, false),
                new PadelTemplate("", 5, 0, 0, false),
                new PadelTemplate("", 0, 3, 1, false)
            ];
            persist(entries);
        } else if (stored instanceof Array) {
            for (var i = 0; i < stored.size(); i++) {
                var row = stored[i];
                if (row instanceof Array && (row.size() == 4 || row.size() == 5)) {
                    var name = row[0];
                    var games = row[1];
                    var bestOf = row[2];
                    var rule = row[3];
                    // Templates saved before the scoring option counted every point.
                    var gamesOnly = row.size() == 5 ? row[4] : false;
                    if (name instanceof String && games instanceof Number && games >= 0 && games <= PADEL_MAX_ROUND_GAMES &&
                        bestOf instanceof Number && (bestOf == 0 || bestOf == 1 || bestOf == 3 || bestOf == 5) &&
                        rule instanceof Number && rule >= -1 && rule <= 2 && gamesOnly instanceof Boolean) {
                        entries.add(new PadelTemplate(name, games, bestOf, rule, gamesOnly));
                    }
                }
            }
        }
    }

    function size() as Number {
        return entries.size();
    }

    function get(index as Number) as PadelTemplate {
        return entries[index];
    }

    function save(index as Number?, entry as PadelTemplate) as Boolean {
        var updated = entries.slice(0, entries.size());
        if (index == null) { updated.add(entry); }
        else { updated[index] = entry; }
        return commitEntries(updated);
    }

    function deleteTemplate(index as Number) as Boolean {
        var updated = entries.slice(0, index);
        for (var i = index + 1; i < entries.size(); i++) {
            updated.add(entries[i]);
        }
        return commitEntries(updated);
    }

    private function commitEntries(updated as Array<PadelTemplate>) as Boolean {
        if (!persist(updated)) { return false; }
        entries = updated;
        return true;
    }

    private function persist(templates as Array<PadelTemplate>) as Boolean {
        var stored = new Array<Storage.ValueType>[templates.size()];
        for (var i = 0; i < templates.size(); i++) {
            var entry = templates[i];
            stored[i] = [entry.name, entry.games, entry.bestOf, entry.rule, entry.gamesOnly];
        }
        try {
            Storage.setValue(PADEL_TEMPLATES_KEY, stored);
            return true;
        } catch (error instanceof Lang.StorageFullException) {
            return false;
        }
    }
}

function openPadelSetup(view as MatchView) as Void {
    new PadelSetup(view).open();
}

class PadelSetup {
    private var view as MatchView;
    private var library as PadelTemplateLibrary;
    private var selection as Number = 0;
    private var mode as Symbol = :manual;
    private var draft as PadelTemplate;
    private var roundGames as Number = 7;

    function initialize(matchView as MatchView) {
        view = matchView;
        library = new PadelTemplateLibrary();
        draft = new PadelTemplate("", 0, 3, 0, false);
    }

    function open() as Void {
        var menu = libraryMenu();
        WatchUi.pushView(menu,
            new PadelSetupMenuInput(menu, view, method(:chooseLibraryItem), method(:exitSetup)), WatchUi.SLIDE_IMMEDIATE);
    }

    function exitSetup() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    private function switchMenu(menu as PadelSetupMenu, selected as Method(item as WatchUi.MenuItem) as Void,
        back as Method() as Void) as Void {
        // Keep one setup menu above the match view as the user navigates.
        WatchUi.switchToView(menu, new PadelSetupMenuInput(menu, view, selected, back), WatchUi.SLIDE_IMMEDIATE);
    }

    private function libraryMenu() as PadelSetupMenu {
        var menu = new PadelSetupMenu(library.size() == 0 ? tr("Sin plantillas", "No templates") : tr("Plantillas", "Templates"));
        for (var i = 0; i < library.size(); i++) {
            var entry = library.get(i);
            var caption = entry.scoringSummary();
            if (entry.name.length() > 0) {
                caption = entry.formatLabel() + " · " + (!entry.gamesOnly && entry.rule == 0 ? tr("Oro", "Gold") : caption);
            }
            menu.addItem(new WatchUi.MenuItem(entry.label(), caption, i, {}));
        }
        menu.addItem(new WatchUi.MenuItem("Manual", null, :manual, {}));
        menu.addItem(new WatchUi.MenuItem(tr("Nueva plantilla", "New template"), null, :new, {}));
        menu.setFocus(selection);
        return menu;
    }

    function showLibrary() as Void {
        switchMenu(libraryMenu(), method(:chooseLibraryItem), method(:exitSetup));
    }

    function chooseLibraryItem(item as WatchUi.MenuItem) as Void {
        var choice = item.getId();
        if (choice instanceof Number) {
            selection = choice;
            showTemplate();
        } else {
            selection = library.size() + (choice == :new ? 1 : 0);
            var score = view.score;
            startEditor(choice as Symbol,
                new PadelTemplate("", score.gameLimit, score.bestOf, score.selectedRule, score.gamesOnly));
        }
    }

    function showTemplate() as Void {
        var entry = library.get(selection);
        var menu = new PadelSetupMenu(entry.label());
        menu.addItem(new WatchUi.MenuItem(tr("Usar plantilla", "Use template"), entry.scoringSummary(), :apply, {}));
        menu.addItem(new WatchUi.MenuItem(tr("Editar", "Edit"), entry.name.length() > 0 ? entry.formatLabel() : null, :edit, {}));
        menu.addItem(new WatchUi.MenuItem(tr("Eliminar", "Delete"), null, :delete, {}));
        switchMenu(menu, method(:chooseTemplateAction), method(:showLibrary));
    }

    function chooseTemplateAction(item as WatchUi.MenuItem) as Void {
        var entry = library.get(selection);
        switch (item.getId() as Symbol) {
            case :apply:
                view.applyTemplateSetup(entry.games, entry.bestOf, entry.rule, entry.name, entry.gamesOnly);
                exitSetup();
                break;
            case :edit:
                startEditor(:edit, entry);
                break;
            case :delete:
                var menu = new PadelSetupMenu(tr("¿Eliminar?", "Delete template?"));
                menu.addItem(new WatchUi.MenuItem(tr("Cancelar", "Cancel"), null, :cancel, {}));
                menu.addItem(new WatchUi.MenuItem(tr("Eliminar", "Delete"), entry.label(), :delete, {}));
                switchMenu(menu, method(:confirmDelete), method(:showTemplate));
                break;
        }
    }

    function confirmDelete(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :cancel) {
            showTemplate();
        } else if (library.deleteTemplate(selection)) {
            showLibrary();
        } else {
            showStorageError(method(:showTemplate));
        }
    }

    private function startEditor(editorMode as Symbol, entry as PadelTemplate) as Void {
        mode = editorMode;
        draft = new PadelTemplate(entry.name, entry.games, entry.games > 0 ? 3 : entry.bestOf, entry.rule, entry.gamesOnly);
        roundGames = entry.games > 0 ? entry.games : 7;
        showEditor();
    }

    private function showEditorAt(focus as Number) as Void {
        var menu = new PadelSetupMenu(mode == :manual ? "Manual" : mode == :new ? tr("Crear", "Create") : tr("Editar", "Edit"));
        var americano = draft.games > 0;
        menu.addItem(new WatchUi.MenuItem(tr("Formato", "Format"), americano ? "Americano" : tr("Pádel por sets", "Padel by sets"), :format, {}));
        if (americano) {
            menu.addItem(new WatchUi.MenuItem(tr("Juegos", "Games"), draft.games + tr(" por ronda", " per round"), :games, {}));
        } else {
            menu.addItem(new WatchUi.MenuItem("Sets", padelSetFormat(draft.bestOf), :sets, {}));
        }
        menu.addItem(new WatchUi.MenuItem(tr("Anotar", "Scoring"), draft.scoringLabel(), :scoring, {}));
        if (!draft.gamesOnly) {
            menu.addItem(new WatchUi.MenuItem(tr("Iguales", "Deuce"), padelRuleLabel(draft.rule), :rule, {}));
        }
        if (mode != :manual) {
            menu.addItem(new WatchUi.MenuItem(tr("Nombre", "Name"), draft.nameLabel(), :name, {}));
        }
        menu.addItem(new WatchUi.MenuItem(mode == :manual ? tr("Aplicar", "Apply") : tr("Guardar", "Save"), null, :finish, {}));
        menu.setFocus(focus);
        switchMenu(menu, method(:chooseEditorItem), method(:cancelEditor));
    }

    function showEditor() as Void {
        showEditorAt(0);
    }

    function cancelEditor() as Void {
        if (mode == :edit) { showTemplate(); }
        else { showLibrary(); }
    }

    function chooseEditorItem(item as WatchUi.MenuItem) as Void {
        switch (item.getId() as Symbol) {
            case :format:
                showFormats();
                break;
            case :sets:
                showSets();
                break;
            case :games:
                pickGames(item);
                break;
            case :scoring:
                showScoring();
                break;
            case :rule:
                showRules();
                break;
            case :name:
                var editor = new PadelTemplateNameView(draft.name);
                var updateName = new PadelTemplateNameChange(draft, item);
                WatchUi.pushView(editor, new PadelTemplateNameInput(editor, view, updateName.method(:save)), WatchUi.SLIDE_IMMEDIATE);
                break;
            case :finish:
                finishEditor();
                break;
        }
    }

    private function showFormats() as Void {
        var menu = new PadelSetupMenu(tr("Formato", "Format"));
        menu.addItem(new WatchUi.MenuItem(tr("Pádel", "Padel"), tr("Por sets", "By sets"), :sets, {}));
        menu.addItem(new WatchUi.MenuItem("Americano", tr("Por rondas", "By rounds"), :americano, {}));
        menu.setFocus(draft.games == 0 ? 0 : 1);
        switchMenu(menu, method(:selectFormat), method(:showEditor));
    }

    function selectFormat(item as WatchUi.MenuItem) as Void {
        if (draft.games > 0) { roundGames = draft.games; }
        draft.games = item.getId() == :americano ? roundGames : 0;
        showEditorAt(1);
    }

    private function showSets() as Void {
        var choices = [1, 3, 5, 0];
        var menu = new PadelSetupMenu("Sets");
        for (var i = 0; i < choices.size(); i++) {
            var bestOf = choices[i];
            menu.addItem(new WatchUi.MenuItem(padelSetFormat(bestOf), null, bestOf, {}));
        }
        menu.setFocus(choices.indexOf(draft.bestOf));
        switchMenu(menu, method(:selectSets), method(:showEditor));
    }

    function selectSets(item as WatchUi.MenuItem) as Void {
        draft.bestOf = item.getId() as Number;
        showEditorAt(2);
    }

    private function pickGames(item as WatchUi.MenuItem) as Void {
        var selector = new PadelGamesView(draft.games);
        WatchUi.pushView(selector, new PadelGamesInput(selector, view, draft, item), WatchUi.SLIDE_IMMEDIATE);
    }

    private function showScoring() as Void {
        var menu = new PadelSetupMenu(tr("Anotar", "Scoring"));
        menu.addItem(new WatchUi.MenuItem(padelScoringLabel(false), "15, 30, 40", :byPoint, {}));
        menu.addItem(new WatchUi.MenuItem(padelScoringLabel(true), null, :byGame, {}));
        menu.setFocus(draft.gamesOnly ? 1 : 0);
        switchMenu(menu, method(:selectScoring), method(:showEditor));
    }

    function selectScoring(item as WatchUi.MenuItem) as Void {
        draft.gamesOnly = item.getId() == :byGame;
        showEditorAt(2);
    }

    private function showRules() as Void {
        var details = [tr("Dos puntos de margen", "Win by two points"), tr("En el primer 40-40", "At the first 40-40"),
            tr("En el segundo 40-40", "At the second 40-40"), tr("En el tercer 40-40", "At the third 40-40")];
        var menu = new PadelSetupMenu(tr("Iguales", "Deuce"));
        for (var rule = -1; rule <= 2; rule++) {
            menu.addItem(new WatchUi.MenuItem(padelRuleLabel(rule), details[rule + 1], rule, {}));
        }
        menu.setFocus(draft.rule + 1);
        switchMenu(menu, method(:selectRule), method(:showEditor));
    }

    function selectRule(item as WatchUi.MenuItem) as Void {
        draft.rule = item.getId() as Number;
        showEditorAt(4);
    }

    private function finishEditor() as Void {
        var entry = new PadelTemplate(draft.name, draft.games, draft.games > 0 ? 0 : draft.bestOf, draft.rule, draft.gamesOnly);
        if (mode == :manual) {
            view.applySetup(entry.games, entry.bestOf, entry.rule, "", entry.gamesOnly);
            exitSetup();
            return;
        }
        var index = mode == :edit ? selection : null;
        if (library.save(index, entry)) {
            if (index == null) { selection = library.size() - 1; }
            showTemplate();
        } else {
            showStorageError(method(:showEditor));
        }
    }

    private function showStorageError(back as Method() as Void) as Void {
        var menu = new PadelSetupMenu(tr("Sin espacio", "Storage full"));
        menu.addItem(new WatchUi.MenuItem(tr("Volver", "Back"), null, :back, {}));
        switchMenu(menu, new PadelReturnInput(back).method(:select), back);
    }
}

class PadelSetupMenu extends WatchUi.View {
    private var title as String;
    private var items as Array<WatchUi.MenuItem> = [];
    private var focus as Number = 0;
    private var width as Number = 260;
    private var height as Number = 260;

    function initialize(label as String) {
        View.initialize();
        title = label;
    }

    function addItem(item as WatchUi.MenuItem) as Void {
        items.add(item);
    }

    function setFocus(index as Number) as Void {
        if (index >= 0 && index < items.size()) { focus = index; }
    }

    function move(direction as Number) as Void {
        if (items.size() > 0) { focus = (focus + items.size() + direction) % items.size(); }
    }

    function focusedItem() as WatchUi.MenuItem? {
        return items.size() == 0 ? null : items[focus];
    }

    function onLayout(dc as Graphics.Dc) as Void {
        width = dc.getWidth();
        height = dc.getHeight();
    }

    private function visibleCount() as Number {
        return items.size() > 3 ? 3 : items.size();
    }

    private function firstVisible() as Number {
        if (focus == 0) { return 0; }
        var lastStart = items.size() - visibleCount();
        return focus - 1 < lastStart ? focus - 1 : lastStart;
    }

    private function rowY(row as Number) as Number {
        return height / 2 + (2 * row - visibleCount() + 1) * (height * 9 / 100);
    }

    function selectAt(x as Number, y as Number) as WatchUi.MenuItem? {
        if (x < width * 11 / 100 || x > width * 89 / 100) { return null; }
        var radius = height * 8 / 100;
        for (var row = 0; row < visibleCount(); row++) {
            var center = rowY(row);
            if (y >= center - radius && y <= center + radius) {
                focus = firstVisible() + row;
                return focusedItem();
            }
        }
        return null;
    }

    function hitsBack(x as Number, y as Number) as Boolean {
        return x >= width / 4 && x <= width * 3 / 4 && y >= height * 84 / 100 && y <= height * 94 / 100;
    }

    private function drawLabel(dc as Graphics.Dc, y as Number, font as Graphics.FontDefinition,
        label as String, color as Graphics.ColorType, maxWidth as Number) as Void {
        var end = label.length();
        var text = label;
        while (end > 0 && dc.getTextWidthInPixels(text, font) > maxWidth) {
            end--;
            text = label.substring(0, end) + "…";
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawArrow(dc as Graphics.Dc, y as Number, direction as Number) as Void {
        var center = width / 2;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(center - 5, y, center, y + 4 * direction);
        dc.drawLine(center, y + 4 * direction, center + 5, y);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        drawLabel(dc, height * 15 / 100, Graphics.FONT_SMALL, title, Graphics.COLOR_YELLOW, width * 62 / 100);
        var start = firstVisible();
        for (var row = 0; row < visibleCount(); row++) {
            var index = start + row;
            var item = items[index];
            var y = rowY(row);
            var caption = item.getSubLabel();
            var color = index == focus ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
            if (index == focus) {
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawRoundedRectangle(width * 11 / 100, y - height * 8 / 100,
                    width * 78 / 100, height * 16 / 100, 8);
            }
            var offset = caption instanceof String ? height * 4 / 100 : 0;
            drawLabel(dc, y - offset, Graphics.FONT_TINY, item.getLabel(), color, width * 72 / 100);
            if (caption instanceof String) {
                drawLabel(dc, y + offset, Graphics.FONT_XTINY, caption, Graphics.COLOR_LT_GRAY, width * 72 / 100);
            }
        }
        if (start > 0) { drawArrow(dc, height * 23 / 100, -1); }
        if (start + visibleCount() < items.size()) { drawArrow(dc, height * 79 / 100, 1); }
        drawLabel(dc, height * 89 / 100, Graphics.FONT_XTINY, tr("BACK  Volver", "BACK"), Graphics.COLOR_LT_GRAY, width / 2);
    }
}

class PadelSetupMenuInput extends WatchUi.InputDelegate {
    private var menu as PadelSetupMenu;
    private var view as MatchView;
    private var selected as Method(item as WatchUi.MenuItem) as Void;
    private var back as Method() as Void;

    function initialize(setupMenu as PadelSetupMenu, matchView as MatchView,
        onItem as Method(item as WatchUi.MenuItem) as Void, onExit as Method() as Void) {
        InputDelegate.initialize();
        menu = setupMenu;
        view = matchView;
        selected = onItem;
        back = onExit;
    }

    function onKey(event as WatchUi.KeyEvent) as Boolean {
        return handleKey(event.getKey());
    }

    function onTap(event as WatchUi.ClickEvent) as Boolean {
        if (!view.touchOn) { return true; }
        var point = event.getCoordinates();
        if (menu.hitsBack(point[0], point[1])) { return handleKey(WatchUi.KEY_ESC); }
        var item = menu.selectAt(point[0], point[1]);
        if (item != null) { selected.invoke(item); }
        return true;
    }

    function onSwipe(event as WatchUi.SwipeEvent) as Boolean {
        return handleSwipe(event.getDirection());
    }

    function handleSwipe(direction as WatchUi.SwipeDirection) as Boolean {
        if (!view.touchOn) { return true; }
        if (direction == WatchUi.SWIPE_LEFT || direction == WatchUi.SWIPE_RIGHT) {
            return handleKey(WatchUi.KEY_ESC);
        }
        if (direction == WatchUi.SWIPE_UP) { return handleKey(WatchUi.KEY_DOWN); }
        if (direction == WatchUi.SWIPE_DOWN) { return handleKey(WatchUi.KEY_UP); }
        return true;
    }

    function handleKey(key as WatchUi.Key) as Boolean {
        if (key == WatchUi.KEY_UP || key == WatchUi.KEY_DOWN) {
            menu.move(key == WatchUi.KEY_UP ? -1 : 1);
            WatchUi.requestUpdate();
        } else if (key == WatchUi.KEY_ENTER) {
            var item = menu.focusedItem();
            if (item != null) { selected.invoke(item); }
        } else if (key == WatchUi.KEY_ESC) {
            back.invoke();
        } else {
            return false;
        }
        return true;
    }
}

class PadelReturnInput {
    private var back as Method() as Void;

    function initialize(onExit as Method() as Void) {
        back = onExit;
    }

    function select(item as WatchUi.MenuItem) as Void {
        back.invoke();
    }
}

class PadelGamesView extends WatchUi.View {
    var value as Number;
    private var width as Number = 260;
    private var height as Number = 260;

    function initialize(games as Number) {
        View.initialize();
        value = games;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        width = dc.getWidth();
        height = dc.getHeight();
    }

    function move(step as Number) as Void {
        value += step;
        if (value < 1) { value = PADEL_MAX_ROUND_GAMES; }
        else if (value > PADEL_MAX_ROUND_GAMES) { value = 1; }
    }

    private function centerText(dc as Graphics.Dc, y as Number, font as Graphics.FontDefinition,
        label as String, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, y, font, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function adjusterX(increase as Boolean) as Number {
        return width * (increase ? 79 : 21) / 100;
    }

    private function drawAdjuster(dc as Graphics.Dc, increase as Boolean) as Void {
        var x = adjusterX(increase);
        var y = height / 2;
        var line = height * 4 / 100;
        dc.drawCircle(x, y, height / 10);
        dc.drawLine(x - line, y, x + line, y);
        if (increase) { dc.drawLine(x, y - line, x, y + line); }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        centerText(dc, height / 5, Graphics.FONT_SMALL, tr("Juegos por ronda", "Games per round"), Graphics.COLOR_WHITE);
        centerText(dc, height / 2, Graphics.FONT_NUMBER_HOT, value.toString(), Graphics.COLOR_WHITE);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        drawAdjuster(dc, false);
        drawAdjuster(dc, true);
        dc.drawRoundedRectangle(width * 24 / 100, height * 70 / 100, width * 52 / 100, height * 13 / 100, 9);
        dc.setPenWidth(1);
        centerText(dc, height * 77 / 100, Graphics.FONT_XTINY, tr("START  Listo", "START  Done"), Graphics.COLOR_YELLOW);
        centerText(dc, height * 89 / 100, Graphics.FONT_XTINY, tr("BACK  Volver", "BACK"), Graphics.COLOR_LT_GRAY);
    }

    function keyAt(x as Number, y as Number) as WatchUi.Key? {
        var dy = y - height / 2;
        var minus = x - adjusterX(false);
        var plus = x - adjusterX(true);
        var radius = height * 11 / 100;
        if (minus * minus + dy * dy <= radius * radius) { return WatchUi.KEY_DOWN; }
        if (plus * plus + dy * dy <= radius * radius) { return WatchUi.KEY_UP; }
        if (x >= width * 24 / 100 && x <= width * 76 / 100) {
            if (y >= height * 70 / 100 && y <= height * 83 / 100) { return WatchUi.KEY_ENTER; }
            if (y >= height * 85 / 100 && y <= height * 93 / 100) { return WatchUi.KEY_ESC; }
        }
        return null;
    }
}

class PadelGamesInput extends WatchUi.InputDelegate {
    private var selector as PadelGamesView;
    private var view as MatchView;
    private var draft as PadelTemplate;
    private var item as WatchUi.MenuItem;

    function initialize(gamesView as PadelGamesView, matchView as MatchView, template as PadelTemplate, menuItem as WatchUi.MenuItem) {
        InputDelegate.initialize();
        selector = gamesView;
        view = matchView;
        draft = template;
        item = menuItem;
    }

    function onKey(event as WatchUi.KeyEvent) as Boolean {
        return handleKey(event.getKey());
    }

    function onTap(event as WatchUi.ClickEvent) as Boolean {
        if (!view.touchOn) { return true; }
        var coordinates = event.getCoordinates();
        var key = selector.keyAt(coordinates[0], coordinates[1]);
        return key != null && handleKey(key);
    }

    function onSwipe(event as WatchUi.SwipeEvent) as Boolean {
        if (view.touchOn && (event.getDirection() == WatchUi.SWIPE_LEFT || event.getDirection() == WatchUi.SWIPE_RIGHT)) {
            return handleKey(WatchUi.KEY_ESC);
        }
        return true;
    }

    private function handleKey(key as WatchUi.Key) as Boolean {
        if (key == WatchUi.KEY_UP || key == WatchUi.KEY_DOWN) {
            selector.move(key == WatchUi.KEY_UP ? 1 : -1);
            WatchUi.requestUpdate();
        } else if (key == WatchUi.KEY_ENTER) {
            draft.games = selector.value;
            item.setSubLabel(draft.games + tr(" por ronda", " per round"));
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (key == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else {
            return false;
        }
        return true;
    }
}

class PadelTemplateNameChange {
    private var draft as PadelTemplate;
    private var item as WatchUi.MenuItem;

    function initialize(template as PadelTemplate, menuItem as WatchUi.MenuItem) {
        draft = template;
        item = menuItem;
    }

    function save(text as String) as Void {
        var chars = text.toCharArray();
        var first = 0;
        var last = chars.size();
        while (first < last && chars[first] == ' ') { first++; }
        while (first < last && chars[last - 1] == ' ') { last--; }
        draft.name = first == last ? "" : text.substring(first, last) as String;
        item.setSubLabel(draft.nameLabel());
    }
}
