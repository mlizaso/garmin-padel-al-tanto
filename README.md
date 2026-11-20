# Padel al Tanto

[![Connect IQ](https://github.com/mlizaso/garmin-padel-al-tanto/actions/workflows/connect-iq.yml/badge.svg)](https://github.com/mlizaso/garmin-padel-al-tanto/actions/workflows/connect-iq.yml)

Marcador de pádel para el **Garmin fēnix 7 y fēnix 7 Pro de 47 mm**. La pareja que saca aparece arriba. Puedes anotar con botones o toques, deshacer, llevar solo los juegos y grabar la actividad con el pulso. Admite partidos por sets y rondas de americano de duración configurable. La interfaz está en español e inglés.

![Marcador a 30–30 en el simulador](Tienda/capturas/01-marcador.png)

Para jugar, descarga el paquete USB de la [última versión](https://github.com/mlizaso/garmin-padel-al-tanto/releases/latest), elige el PRG de tu modelo y sigue la [guía de instalación y controles](PadelAlTanto/LEEME.md) o el [manual visual](Manual-visual-Padel-al-Tanto.pdf). La [galería](Vista-previa/Galeria.html) se puede abrir en un navegador desde una copia local del proyecto.

**For players:** download the USB package from the [latest release](https://github.com/mlizaso/garmin-padel-al-tanto/releases/latest). Copy your model’s `PADELAT.PRG` to `GARMIN/APPS` on your watch and disconnect it. The app follows the watch language, using English for languages other than Spanish. You can choose either language under **Settings → Language**.

## Desarrollo y pruebas

El proyecto Monkey C está en `PadelAlTanto/`. Instala Java 17, el SDK Connect IQ 9.3.0 y los perfiles `fenix7` y `fenix7pro` con [Garmin SDK Manager](https://developer.garmin.com/connect-iq/sdk/). En VS Code puedes abrir esa carpeta y usar la extensión Monkey C. Para probar la versión distribuida en macOS, ejecuta `./Abrir-simulador.command` desde la raíz.

Con el directorio `bin` del SDK en el PATH y el simulador abierto, puedes compilar y probar un modelo desde la raíz. Usa una clave de desarrollo propia en formato DER.

```sh
mkdir -p bin
monkeyc -f PadelAlTanto/monkey.jungle -d fenix7 -r -y /ruta/a/tu-clave.der -o bin/PADELAT.PRG
monkeyc -f PadelAlTanto/monkey.jungle -d fenix7 -t -y /ruta/a/tu-clave.der -o bin/tests.prg
python3 scripts/run_tests.py fenix7 bin/tests.prg
```

Para el modelo Pro, sustituye `fenix7` por `fenix7pro` en los tres comandos. Las pruebas cubren el tanteo, los sets y desempates, el americano, las plantillas, los gestos, el idioma y la lógica de grabación y detección de golpes. La precisión del sensor y la sensación de la vibración se comprueban en pista.

En cada pull request y cada cambio en `main`, [GitHub Actions](.github/workflows/connect-iq.yml) lee los modelos del manifiesto y compila la versión de distribución y la de pruebas para cada reloj. Arranca el simulador de Garmin y verifica que haya pruebas ejecutadas, que todas pasen y que el total coincida. Cada ejecución genera su propia clave temporal. El flujo fija la huella del SDK oficial y de la [imagen de Linux con los perfiles y fuentes](https://github.com/matco/connectiq-tester). Al actualizar el SDK o los perfiles, actualiza la huella correspondiente y comprueba los resultados de los simuladores.

## Actualizar el manual y la galería

Las capturas originales y los generadores están incluidos. Desde la raíz, utiliza Python con Pillow y ReportLab para generar el PDF. El generador usa las fuentes Arial de macOS o las de la carpeta que indiques con `--font-dir`. La galería solo necesita Python.

```sh
python3 tools/manual-visual/manual.py
python3 tools/generar_galeria_padel.py Vista-previa/frames.json Vista-previa/Galeria.html
```
