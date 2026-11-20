import Toybox.Lang;
import Toybox.Test;

(:test)
function countsSeparatedSwingBursts(logger as Test.Logger) as Boolean {
    var detector = new StrokeCounter();
    feedAcceleration(detector, 1000.0, 25);
    // One isolated spike, then a weak burst and then sustained acceleration.
    feedAcceleration(detector, 3200.0, 1);
    feedAcceleration(detector, 1000.0, 1);
    feedAcceleration(detector, 2100.0, 4);
    feedAcceleration(detector, 1000.0, 1);
    feedAcceleration(detector, 3300.0, 12);
    feedAcceleration(detector, 1000.0, 1);
    Test.assertEqual(0, detector.count);

    feedAcceleration(detector, 2400.0, 1);
    feedAcceleration(detector, 3200.0, 1);
    feedAcceleration(detector, 1000.0, 1);
    Test.assertEqual(1, detector.count);
    // A second peak in the follow-through still belongs to the same swing.
    feedAcceleration(detector, 3100.0, 2);
    feedAcceleration(detector, 1000.0, 15);
    Test.assertEqual(1, detector.count);
    feedAcceleration(detector, 3100.0, 2);
    feedAcceleration(detector, 1000.0, 1);
    Test.assertEqual(2, detector.count);
    return true;
}

function feedAcceleration(detector as StrokeCounter, milliG as Float, n as Number) as Void {
    for (var i = 0; i < n; i++) {
        detector.acceptMagnitudeSquared(milliG * milliG);
    }
}
