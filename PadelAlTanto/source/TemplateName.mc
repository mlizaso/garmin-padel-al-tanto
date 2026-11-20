import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class PadelTemplateNameView extends WatchUi.View {
    private const COLUMNS = 7;
    private const LAYOUT = 0;
    private const DELETE = 1;
    private const SAVE = 2;

    private var layouts as Array<String> = [
        "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ ",
        "abcdefghijklmnñopqrstuvwxyz ",
        "0123456789.,-_:;!?¡¿'\"/@&()+",
        "ÁÉÍÓÚÜáéíóúüÀÈÒàèòÇçÂÊÔâêô",
        "#$%*<=>[]\\^`{}|~€ªº«»"
    ];
    private var layoutLabels as Array<String> = ["ABC", "abc", "123", "ÁÉÍ", "#?"];
    private var layoutIndex as Number = 0;
    private var characters as Array<Char>;
    private var focus as Number = 0;
    private var text as String;
    private var width as Number = 260;
    private var height as Number = 260;

    function initialize(name as String) {
        View.initialize();
        text = name;
        characters = layouts[0].toCharArray();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        width = dc.getWidth();
        height = dc.getHeight();
    }

    function getName() as String {
        return text;
    }

    private function keyCount() as Number {
        return characters.size() + 3;
    }

    function moveFocus(step as Number) as Void {
        focus = (focus + step + keyCount()) % keyCount();
    }

    private function nextLayout() as Number {
        return (layoutIndex + 1) % layouts.size();
    }

    function select() as Boolean {
        var action = focus - characters.size();
        if (action < 0) {
            text += characters[focus].toString();
        } else if (action == LAYOUT) {
            layoutIndex = nextLayout();
            characters = layouts[layoutIndex].toCharArray();
            focus = characters.size() + LAYOUT;
        } else if (action == DELETE) {
            var length = text.length();
            text = length > 1 ? text.substring(0, length - 1) as String : "";
        }
        return action == SAVE;
    }

    function selectAt(x as Number, y as Number) as Boolean {
        for (var index = 0; index < keyCount(); index++) {
            var dx = keyX(index) - x;
            var dy = keyY(index) - y;
            var halfWidth = keyWidth(index) / 2;
            var halfHeight = height * 4 / 100;
            if (-halfWidth <= dx && dx <= halfWidth && -halfHeight <= dy && dy <= halfHeight) {
                focus = index;
                return select();
            }
        }
        return false;
    }

    private function keyX(index as Number) as Number {
        var characterCount = characters.size();
        if (index >= characterCount) {
            return width * (23 + (index - characterCount) * 27) / 100;
        }
        var spacing = width * 11 / 100;
        var remaining = characterCount - (index / COLUMNS) * COLUMNS;
        var columns = remaining < COLUMNS ? remaining : COLUMNS;
        return (width - (columns - 1) * spacing) / 2 + (index % COLUMNS) * spacing;
    }

    private function keyY(index as Number) as Number {
        return height * (index >= characters.size() ? 79 : 38 + (index / COLUMNS) * 10) / 100;
    }

    private function keyWidth(index as Number) as Number {
        return width * (index >= characters.size() ? 25 : 10) / 100;
    }

    private function visibleName(dc as Graphics.Dc) as String {
        var maxWidth = width * 72 / 100;
        if (dc.getTextWidthInPixels(text, Graphics.FONT_TINY) <= maxWidth) { return text; }
        var end = text.length();
        var visible = "…";
        for (var start = end - 1; start >= 0; start--) {
            var candidate = "…" + (text.substring(start, end) as String);
            if (dc.getTextWidthInPixels(candidate, Graphics.FONT_TINY) > maxWidth) { break; }
            visible = candidate;
        }
        return visible;
    }

    private function centerText(dc as Graphics.Dc, x as Number, y as Number, label as String,
        font as Graphics.FontDefinition, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawKey(dc as Graphics.Dc, index as Number, label as String,
        font as Graphics.FontDefinition) as Void {
        var x = keyX(index);
        var y = keyY(index);
        var buttonWidth = keyWidth(index);
        var halfHeight = height * 4 / 100;
        var left = x - buttonWidth / 2;
        var top = y - halfHeight;
        if (index == focus) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(left, top, buttonWidth, halfHeight * 2, 4);
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(left, top, buttonWidth, halfHeight * 2, 4);
        }
        centerText(dc, x, y, label, font, index == focus ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        centerText(dc, width / 2, height * 14 / 100, tr("Nombre", "Name"), Graphics.FONT_SMALL, Graphics.COLOR_YELLOW);
        centerText(dc, width / 2, height * 25 / 100, text.length() == 0 ? tr("Automático", "Automatic") : visibleName(dc),
            Graphics.FONT_TINY, Graphics.COLOR_WHITE);
        for (var i = 0; i < characters.size(); i++) {
            var space = characters[i] == ' ';
            drawKey(dc, i, space ? tr("Esp", "Spc") : characters[i].toString(), space ? Graphics.FONT_XTINY : Graphics.FONT_TINY);
        }
        var firstAction = characters.size();
        drawKey(dc, firstAction + LAYOUT, layoutLabels[nextLayout()] + " ›", Graphics.FONT_XTINY);
        drawKey(dc, firstAction + DELETE, tr("Borrar", "Delete"), Graphics.FONT_XTINY);
        drawKey(dc, firstAction + SAVE, tr("Guardar", "Save"), Graphics.FONT_XTINY);
        centerText(dc, width / 2, height * 88 / 100, tr("UP/DOWN · START elige", "UP/DOWN · START selects"), Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY);
        centerText(dc, width / 2, height * 94 / 100, tr("BACK cancela", "BACK cancels"), Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY);
    }
}

class PadelTemplateNameInput extends WatchUi.InputDelegate {
    private var editor as PadelTemplateNameView;
    private var matchView as MatchView;
    private var onSave as Method(name as String) as Void;

    function initialize(view as PadelTemplateNameView, touchView as MatchView, save as Method(name as String) as Void) {
        InputDelegate.initialize();
        editor = view;
        matchView = touchView;
        onSave = save;
    }

    function onKey(event as WatchUi.KeyEvent) as Boolean {
        var key = event.getKey();
        if (key == WatchUi.KEY_UP || key == WatchUi.KEY_DOWN) {
            editor.moveFocus(key == WatchUi.KEY_UP ? -1 : 1);
            WatchUi.requestUpdate();
        } else if (key == WatchUi.KEY_ENTER) {
            applySelection(editor.select());
        } else if (key == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else {
            return false;
        }
        return true;
    }

    function onTap(event as WatchUi.ClickEvent) as Boolean {
        if (matchView.touchOn) {
            var coordinates = event.getCoordinates();
            applySelection(editor.selectAt(coordinates[0], coordinates[1]));
        }
        return true;
    }

    function onSwipe(event as WatchUi.SwipeEvent) as Boolean {
        var direction = event.getDirection();
        if (matchView.touchOn && (direction == WatchUi.SWIPE_LEFT || direction == WatchUi.SWIPE_RIGHT)) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        return true;
    }

    private function applySelection(save as Boolean) as Void {
        if (save) {
            onSave.invoke(editor.getName());
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else {
            WatchUi.requestUpdate();
        }
    }
}
