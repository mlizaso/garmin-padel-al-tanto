import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

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

        Test.assert(library.save(null, new PadelTemplate("Liga", 4, 0, -1, true)));
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
        Test.assert(library.save(1, new PadelTemplate("Mi club", 6, 0, 2, true)));
        Test.assertEqual(4, library.size());
        Test.assert(library.save(null, new PadelTemplate("Viernes", 8, 0, 1, false)));
        Test.assertEqual(5, library.size());

        var restarted = new PadelTemplateLibrary();
        Test.assertEqual(5, restarted.size());
        assertTemplate(restarted.get(1), "Mi club", 6, 0, 2, true);
        assertTemplate(restarted.get(4), "Viernes", 8, 0, 1, false);
        Test.assert(restarted.save(4, new PadelTemplate("Viernes", 0, 5, 0, true)));

        var edited = new PadelTemplateLibrary();
        Test.assertEqual(5, edited.size());
        assertTemplate(edited.get(1), "Mi club", 6, 0, 2, true);
        assertTemplate(edited.get(4), "Viernes", 0, 5, 0, true);
    } finally {
        restoreTemplateStorage(original);
    }
    return true;
}

(:test)
function olderTemplatesKeepTheirSettingsAndCountPoints(logger as Test.Logger) as Boolean {
    var original = Storage.getValue(PADEL_TEMPLATES_KEY);
    try {
        var oldRecords = new Array<Storage.ValueType>[2];
        oldRecords[0] = ["Club", 6, 0, 1];
        oldRecords[1] = ["Torneo", 0, 5, 2];
        Storage.setValue(PADEL_TEMPLATES_KEY, oldRecords);
        var library = new PadelTemplateLibrary();
        Test.assertEqual(2, library.size());
        assertTemplate(library.get(0), "Club", 6, 0, 1, false);
        assertTemplate(library.get(1), "Torneo", 0, 5, 2, false);

        Test.assert(library.save(0, new PadelTemplate("Club", 6, 0, 1, true)));
        var restarted = new PadelTemplateLibrary();
        Test.assertEqual(2, restarted.size());
        assertTemplate(restarted.get(0), "Club", 6, 0, 1, true);
        assertTemplate(restarted.get(1), "Torneo", 0, 5, 2, false);
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
