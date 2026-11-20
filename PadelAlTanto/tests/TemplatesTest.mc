import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

(:test)
function playSelectorOffersSavedTemplatesAndManual(logger as Test.Logger) as Boolean {
    var original = Storage.getValue(PADEL_TEMPLATES_KEY);
    try {
        var saved = new Array<Storage.ValueType>[1];
        saved[0] = ["Club", 7, 0, 1, true, false];
        Storage.setValue(PADEL_TEMPLATES_KEY, saved);
        var view = new MatchView();

        Test.assertEqual(:play, view.menuItems()[0]);
        var play = view.activateMenu(0) as PadelSetup;
        var selector = play.libraryMenu();
        Test.assertEqual(HOME, view.page);
        Test.assertEqual("Club", (selector.focusedItem() as WatchUi.MenuItem).getLabel());
        selector.move(-1);
        Test.assertEqual(:manual, (selector.focusedItem() as WatchUi.MenuItem).getId());
        selector.move(1);
        play.chooseLibraryItem(selector.focusedItem() as WatchUi.MenuItem);
        Test.assertEqual(READY, view.page);
        Test.assertEqual("Club", view.setupName);
        Test.assertEqual(7, view.score.gameLimit);
        Test.assert(view.score.gamesOnly);
        Test.assert(view.recording.session == null);

        view.backFromServe();
        play.exitSetup();
        Test.assertEqual(:templates, view.menuItems()[1]);
        var management = view.activateMenu(1) as PadelSetup;
        var library = management.libraryMenu();
        management.chooseLibraryItem(library.focusedItem() as WatchUi.MenuItem);
        var actions = management.templateMenu();
        Test.assertEqual(HOME, view.page);
        Test.assertEqual(:edit, (actions.focusedItem() as WatchUi.MenuItem).getId());
        actions.move(1);
        Test.assertEqual(:delete, (actions.focusedItem() as WatchUi.MenuItem).getId());
        actions.move(1);
        Test.assertEqual(:edit, (actions.focusedItem() as WatchUi.MenuItem).getId());
        management.exitSetup();

        Storage.setValue(PADEL_TEMPLATES_KEY, new Array<Storage.ValueType>[0]);
        var manualPlay = view.activateMenu(0) as PadelSetup;
        var emptySelector = manualPlay.libraryMenu();
        Test.assertEqual(:manual, (emptySelector.focusedItem() as WatchUi.MenuItem).getId());
        emptySelector.move(1);
        Test.assertEqual(:manual, (emptySelector.focusedItem() as WatchUi.MenuItem).getId());
        manualPlay.chooseLibraryItem(emptySelector.focusedItem() as WatchUi.MenuItem);
        var custom = manualPlay.editorMenu(0);
        Test.assertEqual(:format, (custom.focusedItem() as WatchUi.MenuItem).getId());
        custom.move(-1);
        var continueItem = custom.focusedItem() as WatchUi.MenuItem;
        Test.assertEqual(:finish, continueItem.getId());
        Test.assertEqual(tr("Continuar", "Continue"), continueItem.getLabel());
        manualPlay.chooseEditorItem(continueItem);
        Test.assertEqual(READY, view.page);
        Test.assertEqual("", view.setupName);
        Test.assertEqual(0, new PadelTemplateLibrary().size());
    } finally {
        restoreTemplateStorage(original);
    }
    return true;
}

(:test)
function templatesSeedOnceAndAllowDeletingTheLastOne(logger as Test.Logger) as Boolean {
    var original = Storage.getValue(PADEL_TEMPLATES_KEY);
    try {
        Storage.deleteValue(PADEL_TEMPLATES_KEY);
        var library = new PadelTemplateLibrary();
        Test.assertEqual(4, library.size());
        assertTemplate(library.get(0), "", 0, 3, 0, false);
        assertTemplate(library.get(1), "", 7, 0, 0, false);
        assertTemplate(library.get(2), "", 5, 0, 0, false);
        assertTemplate(library.get(3), "", 0, 3, 1, false);

        while (library.size() > 0) {
            Test.assert(library.deleteTemplate(0));
            var stored = new PadelTemplateLibrary();
            Test.assertEqual(library.size(), stored.size());
            library = stored;
        }
        Test.assertEqual(0, new PadelTemplateLibrary().size());

        Test.assert(library.save(null, new PadelTemplate("Liga", 4, 0, -1, true, false)));
        var restarted = new PadelTemplateLibrary();
        Test.assertEqual(1, restarted.size());
        assertTemplate(restarted.get(0), "Liga", 4, 0, -1, true);
    } finally {
        restoreTemplateStorage(original);
    }
    return true;
}

(:test)
function templatesPersistNewAndEditedEntriesInPlace(logger as Test.Logger) as Boolean {
    var original = Storage.getValue(PADEL_TEMPLATES_KEY);
    try {
        Storage.deleteValue(PADEL_TEMPLATES_KEY);
        var library = new PadelTemplateLibrary();
        Test.assert(library.save(1, new PadelTemplate("Mi club", 6, 0, 2, true, false)));
        Test.assertEqual(4, library.size());
        Test.assert(library.save(null, new PadelTemplate("Viernes", 0, 3, 1, true, true)));
        Test.assertEqual(5, library.size());

        var restarted = new PadelTemplateLibrary();
        Test.assertEqual(5, restarted.size());
        assertTemplate(restarted.get(1), "Mi club", 6, 0, 2, true);
        assertTemplate(restarted.get(4), "Viernes", 0, 3, 1, true);
        Test.assert(restarted.get(4).matchTieBreakEnabled);
        Test.assert(restarted.save(4, new PadelTemplate("Viernes", 0, 5, 0, true, true)));

        var edited = new PadelTemplateLibrary();
        Test.assertEqual(5, edited.size());
        assertTemplate(edited.get(1), "Mi club", 6, 0, 2, true);
        assertTemplate(edited.get(4), "Viernes", 0, 5, 0, true);
        Test.assert(!edited.get(4).matchTieBreakEnabled);
    } finally {
        restoreTemplateStorage(original);
    }
    return true;
}

(:test)
function olderTemplatesKeepTheirSettingsAndCountPoints(logger as Test.Logger) as Boolean {
    var original = Storage.getValue(PADEL_TEMPLATES_KEY);
    try {
        var oldRecords = new Array<Storage.ValueType>[3];
        oldRecords[0] = ["Club", 6, 0, 1];
        oldRecords[1] = ["Torneo", 0, 5, 2];
        oldRecords[2] = ["Rápido", 0, 3, 0, true];
        Storage.setValue(PADEL_TEMPLATES_KEY, oldRecords);
        var library = new PadelTemplateLibrary();
        Test.assertEqual(3, library.size());
        assertTemplate(library.get(0), "Club", 6, 0, 1, false);
        assertTemplate(library.get(1), "Torneo", 0, 5, 2, false);
        assertTemplate(library.get(2), "Rápido", 0, 3, 0, true);
        Test.assert(!library.get(2).matchTieBreakEnabled);

        Test.assert(library.save(0, new PadelTemplate("Club", 6, 0, 1, true, false)));
        var restarted = new PadelTemplateLibrary();
        Test.assertEqual(3, restarted.size());
        assertTemplate(restarted.get(0), "Club", 6, 0, 1, true);
        assertTemplate(restarted.get(1), "Torneo", 0, 5, 2, false);
        assertTemplate(restarted.get(2), "Rápido", 0, 3, 0, true);
        Test.assert(!restarted.get(2).matchTieBreakEnabled);
        Test.assertEqual(tr("Solo juegos", "Games only"), restarted.get(0).scoringSummary());
        Test.assertEqual(tr("Oro tras 2 ventajas", "Gold after 2 advantages"), restarted.get(1).scoringSummary());
    } finally {
        restoreTemplateStorage(original);
    }
    return true;
}

(:test)
function templateNamesOnlyLocalizeWhenAutomatic(logger as Test.Logger) as Boolean {
    var originalTemplates = Storage.getValue(PADEL_TEMPLATES_KEY);
    var originalLanguage = Storage.getValue("uiLanguage");
    try {
        var stored = new Array<Storage.ValueType>[3];
        stored[0] = ["", 0, 3, 0];
        stored[1] = ["Mejor de 3", 7, 0, 1, true];
        stored[2] = [" Peña Ñ ", 0, 0, 2, false];
        Storage.setValue(PADEL_TEMPLATES_KEY, stored);
        PadelLanguage.setEnglish(false);
        var library = new PadelTemplateLibrary();
        Test.assertEqual("Mejor de 3", library.get(0).label());
        Test.assertEqual("Automático", library.get(0).nameLabel());

        PadelLanguage.setEnglish(true);
        Test.assertEqual("Best of 3", library.get(0).label());
        Test.assertEqual("Automatic", library.get(0).nameLabel());
        Test.assertEqual("Golden point", library.get(0).scoringSummary());
        Test.assertEqual("Mejor de 3", library.get(1).label());
        Test.assertEqual("Americano 7", library.get(1).formatLabel());
        Test.assertEqual("Games only", library.get(1).scoringSummary());
        Test.assertEqual(" Peña Ñ ", new PadelTemplateLibrary().get(2).label());
    } finally {
        restoreTemplateStorage(originalTemplates);
        if (originalLanguage == null) { Storage.deleteValue("uiLanguage"); }
        else { Storage.setValue("uiLanguage", originalLanguage); }
        PadelLanguage.reload();
    }
    return true;
}

(:test)
function americanoGamesSelectorCoversEntireRange(logger as Test.Logger) as Boolean {
    var selector = new PadelGamesView(1);
    selector.move(-1);
    Test.assertEqual(99, selector.value);
    selector.move(1);
    for (var games = 1; games <= 99; games++) {
        Test.assertEqual(games, selector.value);
        selector.move(1);
    }
    Test.assertEqual(1, selector.value);
    Test.assertEqual(WatchUi.KEY_DOWN, selector.keyAt(54, 130));
    Test.assertEqual(WatchUi.KEY_UP, selector.keyAt(205, 130));
    Test.assertEqual(WatchUi.KEY_ENTER, selector.keyAt(130, 200));
    Test.assertEqual(WatchUi.KEY_ESC, selector.keyAt(130, 231));
    Test.assert(selector.keyAt(130, 130) == null);
    return true;
}

function assertTemplate(entry as PadelTemplate, name as String, games as Number,
    bestOf as Number, rule as Number, gamesOnly as Boolean) as Void {
    Test.assertEqual(name, entry.name);
    Test.assertEqual(games, entry.games);
    Test.assertEqual(bestOf, entry.bestOf);
    Test.assertEqual(rule, entry.rule);
    Test.assertEqual(gamesOnly, entry.gamesOnly);
}

function restoreTemplateStorage(original as Storage.ValueType) as Void {
    if (original == null) { Storage.deleteValue(PADEL_TEMPLATES_KEY); }
    else { Storage.setValue(PADEL_TEMPLATES_KEY, original); }
}
