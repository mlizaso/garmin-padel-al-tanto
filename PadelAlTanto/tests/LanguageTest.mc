import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

(:test)
function languageDefaultsToSpanishOnSpanishWatches(logger as Test.Logger) as Boolean {
    Test.assert(!PadelLanguage.resolveEnglish(null, System.LANGUAGE_SPA));
    Test.assert(PadelLanguage.resolveEnglish(null, System.LANGUAGE_ENG));
    Test.assert(PadelLanguage.resolveEnglish(null, System.LANGUAGE_FRE));
    Test.assert(!PadelLanguage.resolveEnglish("fr", System.LANGUAGE_SPA));
    Test.assert(PadelLanguage.resolveEnglish(true, System.LANGUAGE_FRE));
    Test.assert(PadelLanguage.resolveEnglish("en", System.LANGUAGE_SPA));
    Test.assert(!PadelLanguage.resolveEnglish("es", System.LANGUAGE_FRE));
    return true;
}

(:test)
function languageRemembersExplicitChoices(logger as Test.Logger) as Boolean {
    var saved = Storage.getValue("uiLanguage");
    try {
        Storage.deleteValue("uiLanguage");
        PadelLanguage.reload();
        var expected = System.getDeviceSettings().systemLanguage == System.LANGUAGE_SPA ? "Jugar" : "Play";
        Test.assertEqual(expected, tr("Jugar", "Play"));
        Test.assert(Storage.getValue("uiLanguage") == null);
        Storage.setValue("uiLanguage", "fr");
        PadelLanguage.reload();
        Test.assertEqual(expected, tr("Jugar", "Play"));
        PadelLanguage.setEnglish(true);
        PadelLanguage.reload();
        Test.assertEqual("en", Storage.getValue("uiLanguage"));
        Test.assertEqual("Play", tr("Jugar", "Play"));
        PadelLanguage.setEnglish(false);
        PadelLanguage.reload();
        Test.assertEqual("es", Storage.getValue("uiLanguage"));
        Test.assertEqual("Jugar", tr("Jugar", "Play"));
    } finally {
        if (saved == null) { Storage.deleteValue("uiLanguage"); }
        else { Storage.setValue("uiLanguage", saved); }
        PadelLanguage.reload();
    }
    return true;
}
