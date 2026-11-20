import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;

module PadelLanguage {
    var english as Boolean?;

    function reload() as Void {
        english = resolveEnglish(Storage.getValue("uiLanguage"), System.getDeviceSettings().systemLanguage);
    }

    function resolveEnglish(saved as Storage.ValueType, watchLanguage as System.Language) as Boolean {
        if (saved instanceof String) {
            if (saved.equals("es")) { return false; }
            if (saved.equals("en")) { return true; }
        }
        return watchLanguage != System.LANGUAGE_SPA;
    }

    function isEnglish() as Boolean {
        if (english == null) { reload(); }
        return english == true;
    }

    function setEnglish(value as Boolean) as Void {
        Storage.setValue("uiLanguage", value ? "en" : "es");
        english = value;
    }
}

function tr(spanish as String, english as String) as String {
    return PadelLanguage.isEnglish() ? english : spanish;
}
