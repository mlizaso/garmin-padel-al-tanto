import Toybox.Lang;
import Toybox.Test;

(:test)
function templateNameEditorSupportsButtonsAndAccents(logger as Test.Logger) as Boolean {
    var editor = new PadelTemplateNameView("Peñ");
    editor.moveFocus(-1);
    Test.assert(editor.select());
    Test.assertEqual("Peñ", editor.getName());
    editor.moveFocus(-1);
    Test.assert(!editor.select());
    Test.assertEqual("Pe", editor.getName());

    // Go from Borrar to the layout switch and advance to accents.
    editor.moveFocus(-1);
    for (var i = 0; i < 3; i++) {
        Test.assert(!editor.select());
    }
    Test.assert(!editor.selectAt(214, 98));
    Test.assertEqual("Peá", editor.getName());

    Test.assert(!editor.selectAt(130, 205));
    Test.assert(!editor.select());
    Test.assert(!editor.select());
    Test.assert(!editor.select());
    Test.assertEqual("", editor.getName());
    Test.assert(editor.selectAt(200, 205));
    return true;
}
