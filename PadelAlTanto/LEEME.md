# Padel al Tanto · Versión 0.8.0

[Abrir el manual visual en PDF](../Manual-visual-Padel-al-Tanto.pdf)

Aplicación de reloj para el Garmin fēnix 7 estándar de 47 mm (`fenix7`) y el fēnix 7 Pro de 47 mm (`fenix7pro`), incluida la edición Pro Sapphire Solar. El marcador funciona en el reloj. También puedes activar la estimación de golpes a partir del movimiento de la muñeca.

## Probar en el simulador

Instala el SDK de Connect IQ y la extensión Monkey C como se explica en [Compilar otra versión](#compilar-otra-versión). Abre esta carpeta en Visual Studio Code, selecciona un archivo `.mc` de `source/` y elige **Ejecutar → Ejecutar sin depurar**. Elige **fēnix 7** o **fēnix 7 Pro** cuando se abra el selector de dispositivos. En el simulador, usa **↑** y **↓** para recorrer las opciones o anotar, **Intro** para START y **Esc** para BACK. También puedes hacer clic en la esfera y arrastrar horizontalmente para volver.

## Instalar en el reloj

1. Descarga y descomprime el ZIP de instalación de la sección **Releases** del repositorio. Conecta el fēnix 7 al ordenador con un cable USB de datos. Si pregunta por el modo de conexión, elige transferencia de archivos o MTP.
2. En Windows, abre el reloj en el Explorador de archivos. En Mac, si el reloj no aparece en Finder, cierra Garmin Express por completo y abre un cliente MTP, por ejemplo Android File Transfer si ya lo tienes instalado.
3. Para el fēnix 7 Pro de 47 mm, incluida la edición Sapphire Solar, selecciona **fenix7pro/PADELAT.PRG** en el ZIP descomprimido. Para el fēnix 7 estándar de 47 mm, selecciona **PADELAT.PRG** en la raíz. Copia el archivo de tu modelo en **Almacenamiento interno → GARMIN → APPS**. Espera a que termine la copia y desconecta el reloj.
4. Desde la esfera, pulsa **START** y busca **Padel al Tanto** en la lista. La aplicación inicia su propia actividad de pádel. Mantén el sensor de frecuencia cardíaca de muñeca en **Auto** o conecta tu banda habitual.

Si actualizas una copia instalada manualmente, conserva una copia del PRG anterior. Para mantener el nombre de archivo con el que el reloj guarda tus ajustes, reemplázalo utilizando ese mismo nombre.

[Instalación manual oficial de Garmin](https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/) · [Conexiones MTP en macOS](https://support.garmin.com/en-US/?faq=zUa4z1zKNn39o6JiqZDHNA)

## Jugar

En el inicio de Padel al Tanto verás **Jugar**, **Plantillas** y **Ajustes** (**Play**, **Templates** y **Settings** en inglés). Toca una fila o muévete con UP/DOWN y pulsa START para elegirla.

* **Jugar** te lleva a **Primer saque**. Elige la pareja y pulsa START para empezar la grabación.
* **Plantillas** reúne el formato de partido, el americano, las reglas y la configuración manual.
* **Ajustes → Pantalla táctil** guarda tu preferencia para toda la aplicación. Toca la fila **Pantalla táctil** o selecciónala con UP/DOWN y pulsa START para alternar entre **Sí** y **No**. Con el táctil desactivado, usa los botones físicos. Las plantillas conservan esta preferencia al cambiar de formato.
* **Ajustes → Detección de golpes** activa o desactiva la estimación de golpes. La opción empieza desactivada y el reloj recuerda el estado que elijas.

Con la pantalla táctil activada, desliza desde el borde derecho hacia la izquierda para hacer lo mismo que BACK. También puedes deslizar en sentido contrario. En un menú vuelves un nivel, al editar un nombre cancelas la edición y en el marcador deshaces la última anotación. Un deslizamiento vertical en el marcador conserva el tanteo.

### Cambiar el idioma

Abre **Ajustes → Idioma** (**Settings → Language** en inglés). Con los botones, pulsa UP/DOWN para seleccionar **Idioma** y pulsa START. Elige **Español** o **English** con UP/DOWN y confirma con START. Con la pantalla táctil activa, también puedes tocar la fila **Idioma** y después el idioma que prefieras.

Antes de elegir, la app usa español si el reloj está en español e inglés con cualquier otro idioma del reloj. La app cambia de idioma al instante y recuerda tu elección al volver a abrirla. Durante un partido puedes abrir el mismo ajuste con **START → Ajustes → Idioma**. Para volver al marcador, pulsa BACK desde Ajustes y otra vez desde el menú.

### Partido normal o americano

En un **partido por sets**, al mejor de tres gana la primera pareja que consigue dos sets. Al mejor de cinco hacen falta tres. En un **americano**, eliges cuántos juegos se disputan en total por ronda, de 1 a 99. Dentro de cada juego se cuentan 15–30–40 y se aplica la regla de iguales que hayas elegido.

La primera vez encontrarás cuatro plantillas. Puedes usar cualquiera directamente o guardar tu propia combinación.

| Plantilla inicial | Cuándo termina | Regla en 40–40 |
|---|---|---|
| Partido al mejor de tres | Una pareja gana dos sets | Punto de oro inmediato |
| Americano a siete | Suman siete juegos | Punto de oro inmediato |
| Americano a cinco | Suman cinco juegos | Punto de oro inmediato |
| Partido al mejor de tres con una ventaja | Una pareja gana dos sets | Tras perder la primera ventaja, el siguiente punto decide |

En el inicio, abre **Plantillas**. Elige una y pulsa **Usar plantilla**. En **Primer saque** verás el formato y la regla antes de empezar. BACK te devuelve al inicio.

* **Manual** aplica el formato, el modo de anotación, el número de juegos o sets y, cuando corresponda, la regla de iguales solo al partido que vas a jugar.
* **Nueva plantilla** guarda esa combinación para otra sesión. Puedes ponerle un nombre propio, como «Club», o conservar el nombre automático. Tras pulsar **Guardar**, elige **Usar plantilla** para jugar con ella.
* Para modificar o eliminar una plantilla, elígela en la lista y pulsa **Editar** o **Eliminar**. También puedes eliminar las cuatro iniciales. La próxima vez se conservará tu lista, incluso vacía.

### Anotar cada punto o solo los juegos

Dentro de **Manual**, **Nueva plantilla** o **Editar**, abre **Anotar**. Las cuatro plantillas iniciales vienen en **Cada punto**. Puedes guardar **Solo juegos** en cualquier plantilla, tanto de partido por sets como de americano.

Con **Solo juegos**, espera a que termine el juego y pulsa la cifra de la pareja que lo ha ganado. UP adjudica el juego a la pareja que sacaba, DOWN a la que restaba. Las cifras grandes muestran juegos. El reloj cambia el saque, calcula los sets y cierra el partido o la ronda al alcanzar el límite elegido. Si llegáis a 6–6 en un set, jugad el desempate en pista y anota una sola vez quién lo ganó. El set quedará en 7–6. En un americano a seis, el 3–3 cierra la ronda.

BACK deshace el último juego y recupera el saque anterior. El historial muestra los cinco últimos juegos anotados. En **Cada punto**, esos mismos controles e historial funcionan punto a punto.

| Situación | Qué pasa en el americano |
|---|---|
| 3–1 en una ronda de cinco | Falta un juego. La ronda llegará a 4–1 o 3–2. |
| 3–2 en una ronda de cinco | Se cierra la ronda. Puedes revisar el resultado, corregir el último punto o continuar. |
| 3–3 en una ronda de seis | La ronda se cierra en empate. Puedes pasar al próximo emparejamiento. |
| 6–0 en una ronda de siete | Aún se juega el séptimo. Los posibles resultados finales son 7–0 y 6–1. |
| Cambio de compañeros | Confirma la siguiente ronda y elige qué pareja saca primero. Todos los parciales se leen con tu pareja primero. |

En la pantalla de **ronda completa**, BACK deshace la última anotación (punto o juego), START prepara la siguiente ronda y DOWN permite guardar la sesión. Al empezar la siguiente eliges el primer saque y confirmas con START. El pulso y el tiempo siguen registrándose entre rondas. Si guardas una ronda incompleta, el archivo de actividad conserva los juegos terminados y añade un asterisco a ese parcial.

### Controles

| Acción | Control |
|---|---|
| Elegir la pareja que saca primero | UP selecciona **Nosotros** y DOWN selecciona **Rivales**. START inicia la grabación. |
| Punto para la pareja al saque | UP o un toque en la fila superior, marcada **SAQUE**. |
| Punto para la pareja al resto | DOWN o un toque en la fila inferior. |
| Restar a una pareja | Con el táctil activo, toca el botón de restar (−) de su fila. Se quita su último punto del juego actual, aunque la otra pareja haya puntuado después. Justo al terminar un juego o set, tocar el botón de restar de la pareja ganadora permite reabrirlo. |
| Deshacer | BACK vuelve al punto anterior. Se puede repetir, incluso al cambiar de juego o de set. La grabación de la actividad sigue en marcha. |
| Ver los últimos cinco puntos o juegos | Durante el juego, toca **Historial** abajo a la izquierda o pulsa START y elige **Historial**. Al cerrarse una ronda o un partido también puedes pulsar UP. |
| Bloquear o activar los toques | En el inicio elige **Ajustes**. Durante el partido, pulsa START y elige **Ajustes**, la primera fila. Selecciona **Pantalla táctil** y pulsa START para cambiar su estado. |
| Terminar | Pulsa START, elige **Terminar partido** y confirma con START. BACK desde la confirmación vuelve al marcador. |
| Ver los parciales al terminar | UP y DOWN recorren los resultados de los sets o de las rondas del americano. BACK sale. |

Los puntos grandes y el botón de cada fila corresponden a la pareja **que ocupa esa fila en ese momento**. Con 30–30, toca arriba para dar el 40–30 a quien saca. Al acabar el juego las parejas cambian de fila. En el tie-break la primera pareja saca un punto y después se alternan cada dos puntos. El tanteo distingue a las dos parejas durante todo el partido.

El historial empieza por la anotación más reciente. **Nos.** y **Riv.** indican quién ganó el punto o juego. Los dos números siempre se leen como **nosotros–rivales**. Al corregir o deshacer, el historial se recalcula. En americano, **R1**, **R2**… identifican la ronda. Desde **Última sesión** en el inicio puedes consultar las últimas cinco anotaciones de la actividad guardada.

El reloj emite una vibración breve al sumar un punto y otra más larga al cerrar un juego. El cierre de ronda usa dos pulsos iguales, el de set uno corto y otro largo, y el de partido tres. En el simulador puedes probar todo el recorrido del marcador. La intensidad en la muñeca se comprueba en el reloj.

### Elegir la regla de 40–40

Antes de jugar, elige la regla en **Plantillas → Manual → Iguales** o en el editor de una plantilla. Durante un partido anotado punto a punto, pulsa START y elige **Regla en iguales**. Selecciona con UP/DOWN y confirma con START.

| Regla | ¿Cuándo decide el siguiente punto? |
|---|---|
| Ventaja | Hay que ganar dos puntos seguidos desde iguales. Cada vez que se pierde la ventaja se vuelve a 40–40. |
| Punto de oro | En el primer 40–40. |
| Una ventaja y oro | Si se pierde la primera ventaja y se vuelve a iguales. |
| Dos ventajas y oro (Star Point) | Si se pierden dos ventajas y se llega a iguales por tercera vez. |

La pareja que gana dos puntos seguidos desde iguales cierra el juego en cualquiera de los modos con ventaja. Puedes cambiar de regla en la aplicación. Si ya has anotado algún punto, el juego en curso conserva la regla con la que empezó. En 0–0 la regla elegida se aplica al juego que va a empezar.

Un set se gana al llegar al menos a seis juegos con dos de diferencia. En 6–6 comienza el tie-break a siete puntos con dos de diferencia, con independencia de la regla que elijas para 40–40. Puedes guardar la actividad antes de terminar un set. Si el ajuste táctil de la app está activo y el reloj ignora los toques, revisa que el sistema permita el táctil durante la actividad.

## Pulsaciones, resultado y estimación de golpes

En la cabecera el reloj muestra las pulsaciones por minuto cuando hay datos disponibles. Para ver también los golpes estimados, abre **Ajustes → Detección de golpes** (**Settings → Stroke detection** en inglés). Toca esa fila o selecciónala con UP/DOWN y pulsa START para cambiar a **Sí**. Durante el partido, abre el mismo ajuste con **START → Ajustes**. La detección empieza a partir del momento en que la activas. Si la apagas, el reloj deja de leer el movimiento y conserva el recuento acumulado de la sesión. El tiempo y el pulso disponible se registran independientemente de este ajuste. Dos guiones indican que todavía faltan datos del sensor.

Al guardar, el reloj crea una actividad de pádel en formato FIT. Sincroniza con Garmin Connect para revisar la duración y la curva de frecuencia cardíaca cuando haya datos. En un partido normal se exportan los sets y los parciales. En americano, se exportan el número de rondas completas y los parciales por orden. Si hubo muestras válidas con la detección activa, el reloj guarda también la estimación de golpes. El asterisco indica un parcial incompleto. Cuando el texto supera el espacio del campo FIT se conservan los parciales más recientes con «...» al principio.

En una instalación manual de desarrollo, Garmin Connect puede ocultar los campos personalizados aunque estén en el FIT. Puedes consultar el tanteo y los golpes en el reloj antes de salir del resumen. Para inspeccionar el archivo, exporta el original de la actividad desde Garmin Connect web.

El contador estima **movimientos de tu brazo de pala**. Usa el acelerómetro a 25 Hz y busca ráfagas breves con un pico de aceleración, independientemente de la orientación de la muñeca. Una volea corta puede pasar inadvertida y un gesto rápido sin pelota puede sumar. Los golpes estimados nunca cambian el marcador.

**Primera prueba en pista.** Activa la detección de golpes y lleva el reloj en el brazo de la pala. Antes de jugar, deja el brazo quieto unos segundos y anota el valor inicial. Cuenta 20 golpes reales, espera dos segundos después del último y compara el incremento. Prueba después con unos pasos y varios gestos sin pelota para ver cuántos registra de más. Para validar el marcador, cierra un juego, pulsa BACK y comprueba que recuperas tanto la puntuación como la pareja al saque.

[API de sensores y acelerómetro](https://developer.garmin.com/connect-iq/api-docs/Toybox/Sensor.html) · [Grabación de actividad](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording.html) · [Campos FIT](https://developer.garmin.com/connect-iq/api-docs/Toybox/FitContributor.html)

## Compilar otra versión

1. Instala el SDK Manager oficial de Garmin y la extensión **Monkey C** de Garmin para Visual Studio Code. En SDK Manager instala el SDK y los perfiles para **fēnix 7** y **fēnix 7 Pro** según los modelos que quieras probar.
2. Abre la carpeta que contiene `manifest.xml` y `monkey.jungle` en Visual Studio Code. Desde la paleta ejecuta **Monkey C: Verify Installation**. Si hace falta, usa **Monkey C: Generate a Developer Key** y guarda la clave en privado.
3. Ejecuta **Monkey C: Build for Device**, selecciona **fēnix 7** o **fēnix 7 Pro** según tu reloj y elige una carpeta de salida. Instala el PRG resultante por USB.

[SDK y configuración del entorno](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/)

## Ejecutar las pruebas

En Visual Studio Code, abre el explorador de pruebas de Monkey C, configura uno de los dos dispositivos y ejecuta las pruebas de `tests/` en el simulador. También puedes usar **Monkey C: Run Tests** desde la paleta de comandos.

[Pruebas unitarias en Connect IQ](https://developer.garmin.com/connect-iq/core-topics/unit-testing/)
