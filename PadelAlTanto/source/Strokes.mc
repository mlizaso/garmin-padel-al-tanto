import Toybox.Lang;
import Toybox.Sensor;

// Estimates racket-arm swings from acceleration magnitude, including gravity.
class StrokeCounter {
    const RATE = 25;
    const MOTION_SQUARED = 1900.0 * 1900.0;
    const PEAK_SQUARED = 3000.0 * 3000.0;
    const MAX_BURST = 10;       // 400 ms at 25 Hz
    const COOLDOWN = 13;        // 520 ms between counted bursts

    var count as Number = 0;
    var available as Boolean = false;
    private var _listening as Boolean = false;
    private var _burst as Number = 0;
    private var _peak as Boolean = false;
    private var _cooldown as Number = 0;

    function start() as Void {
        if (_listening) {
            return;
        }
        _burst = 0;
        _peak = false;
        _cooldown = 0;
        try {
            if (Sensor.getMaxSampleRate() < RATE) {
                return;
            }
            Sensor.registerSensorDataListener(method(:onMotion), {
                :period => 1,
                :accelerometer => { :enabled => true, :sampleRate => RATE }
            });
            _listening = true;
        } catch (e) {
            // The session and manual scoring remain usable if the sensor is busy.
        }
    }

    function stop() as Void {
        if (_listening) {
            _listening = false;
            try {
                Sensor.unregisterSensorDataListener();
            } catch (e) {
                // Ignore late callbacks even if the device already removed the listener.
            }
        }
    }

    function onMotion(data as Sensor.SensorData) as Void {
        if (!_listening) {
            return;
        }
        var accel = data.accelerometerData;
        if (accel == null) {
            return;
        }
        var x = accel.x;
        var y = accel.y;
        var z = accel.z;
        for (var i = 0; i < x.size(); i++) {
            // Use floats before squaring to avoid overflow on high acceleration.
            var ax = x[i].toFloat();
            var ay = y[i].toFloat();
            var az = z[i].toFloat();
            acceptMagnitudeSquared(ax * ax + ay * ay + az * az);
            available = true;
        }
    }

    function acceptMagnitudeSquared(magnitude as Float) as Void {
        if (_cooldown > 0) {
            _cooldown--;
        }
        if (magnitude >= MOTION_SQUARED) {
            if (_burst <= MAX_BURST) {
                _burst++;
            }
            if (magnitude >= PEAK_SQUARED) {
                _peak = true;
            }
            return;
        }

        if (_peak && _burst >= 2 && _burst <= MAX_BURST && _cooldown == 0) {
            count++;
            _cooldown = COOLDOWN;
        }
        _burst = 0;
        _peak = false;
    }
}
