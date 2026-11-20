pages = [
    {
        "title": "Juega con una plantilla",
        "intro": "Usa UP y DOWN para mover el recuadro amarillo y START para elegir. Con el táctil activo, toca la fila que quieras abrir.",
        "steps": [
            (
                "home",
                (130, 122),
                "Abre Plantillas",
                "En el inicio de Padel al Tanto, elige Plantillas, justo debajo de Jugar.",
            ),
            (
                "library",
                (130, 84),
                "Elige la fila del formato",
                "La lista inicial empieza con Mejor de 3, Americano 7 y Americano 5, todos con Punto de oro. Baja para ver el otro Mejor de 3, que lleva Oro tras 1 ventaja.",
            ),
            (
                "template_actions",
                (130, 84),
                "Elige Usar plantilla",
                "Se abre Primer saque con la configuración elegida. Desde ahí, BACK te devuelve al inicio.",
            ),
        ],
        "tip": "Las cuatro plantillas iniciales vienen en Cada punto. La línea debajo del nombre indica la regla de iguales.",
    },
    {
        "title": "Configura tu partido",
        "intro": "En Plantillas puedes ajustar el próximo partido o preparar una configuración para volver a usarla.",
        "steps": [
            (
                "library_end",
                (130, 176),
                "Baja hasta Manual o Nueva plantilla",
                "Elige Manual para preparar el partido que vas a jugar. Elige Nueva plantilla si quieres guardar los ajustes para futuras sesiones.",
            ),
            (
                "editor",
                (130, 84),
                "Abre Formato",
                "El editor de Nueva plantilla se llama Crear. En Crear y en Manual, Formato es la primera fila.",
            ),
            (
                "formats",
                (130, 153),
                "Escoge Pádel o Americano",
                "Pádel organiza el partido por sets. Americano lo divide en rondas con un número fijo de juegos.",
            ),
        ],
        "tip": "Desliza hacia arriba para bajar por una lista o hacia abajo para subir, si tienes el táctil activo.",
    },
    {
        "title": "Elige sets o juegos por ronda",
        "intro": "Después de elegir el formato, el editor muestra Sets para Pádel o Juegos para Americano.",
        "steps": [
            (
                "sets",
                (130, 130),
                'Pádel · Elige los sets',
                "En Mejor de 1, 3 o 5 gana la primera pareja que consigue 1, 2 o 3 sets, respectivamente. Baja hasta Sets sin límite para jugar hasta que decidas terminar.",
            ),
            (
                "americano_editor",
                (130, 130),
                "Americano · Abre Juegos",
                "La fila Juegos muestra el ajuste actual, por ejemplo 7 por ronda. Elígela para abrir el selector.",
            ),
            (
                "games",
                (205, 130),
                "Ajusta los juegos por ronda",
                "Elige de 1 a 99 juegos en total entre ambas parejas. Sube con UP o + y baja con DOWN o −. Pulsa START o toca Listo para confirmar.",
            ),
        ],
        "tip": "En el selector de juegos, bajar desde 1 lleva a 99 y subir desde 99 lleva a 1.",
    },
    {
        "title": "Anota puntos o juegos",
        "intro": "Los dos modos de anotación están disponibles para partidos por sets y para americano.",
        "steps": [
            (
                "editor",
                (130, 176),
                "Abre Anotar",
                "Busca Anotar en el editor. Debajo de la fila aparece el modo seleccionado.",
            ),
            (
                "scoring",
                (130, 107),
                "Cada punto",
                "Anota quién gana cada punto. El reloj muestra el tanteo en 15, 30 y 40 y calcula cuándo se gana el juego.",
            ),
            (
                "scoring",
                (130, 153),
                "Solo juegos",
                "Espera a que se acabe el juego y anota una vez qué pareja lo ha ganado. Las cifras grandes del marcador mostrarán los juegos.",
            ),
        ],
        "tip": "La fila Iguales aparece solo con Cada punto. El ajuste se puede guardar en cualquier plantilla.",
    },
    {
        "title": "Elige la regla de 40–40",
        "intro": "Con Cada punto, la regla de Iguales determina qué pasa cuando las dos parejas llegan a 40.",
        "steps": [
            (
                "editor_bottom",
                (130, 84),
                "Busca Iguales debajo de Anotar",
                "Abre Iguales y recorre las cuatro reglas con UP y DOWN. Pulsa START sobre la que quieras usar o tócala.",
            ),
            (
                "deuce_choices",
                "UP",
                "Ventaja",
                "Sube hasta Ventaja, encima de Punto de oro. Hay que ganar dos puntos seguidos desde 40–40 y cada ventaja perdida devuelve el tanteo a 40–40.",
            ),
            (
                "deuce_choices",
                (130, 130),
                "Cuándo llega el punto de oro",
                "Con Punto de oro, el siguiente punto gana el juego en el primer 40–40. Con Oro tras 1 ventaja, decide en el segundo 40–40. Con Oro tras 2 ventajas (Star Point), decide en el tercero.",
            ),
        ],
        "tip": "En el marcador, AD significa ventaja. «PUNTO DECISIVO» indica que el siguiente punto decide el juego. Dos puntos seguidos desde iguales ganan el juego con cualquier regla.",
    },
    {
        "title": "Pon nombre a la plantilla",
        "intro": "Elige un nombre corto para encontrar tu configuración en la lista.",
        "steps": [
            (
                "editor_bottom",
                (130, 130),
                "Entra en Nombre",
                "En Crear o Editar, baja hasta Nombre. Déjalo vacío si prefieres el nombre automático, como Mejor de 3 o Americano 7.",
            ),
            (
                "name",
                (102, 98),
                "Escribe con el teclado del reloj",
                "Toca una letra o muévete con UP y DOWN y pulsa START para elegirla. Esp añade un espacio y Borrar quita el último carácter.",
            ),
            (
                "name",
                (200, 205),
                "Guarda el nombre",
                "Elige Guardar en el teclado para llevar el texto al editor. Usa BACK para descartar la edición del nombre.",
            ),
        ],
        "tip": "La tecla inferior izquierda, abc › al abrir el teclado, recorre minúsculas, números, letras con tilde, símbolos y mayúsculas.",
    },
    {
        "title": "Aplica o guarda los ajustes",
        "intro": "La última fila del editor depende de cómo hayas entrado.",
        "steps": [
            (
                "manual",
                (130, 176),
                "En Manual, elige Aplicar",
                "Aplicar abre Primer saque con los ajustes para este partido.",
            ),
            (
                "editor_bottom",
                (130, 176),
                "En Crear o Editar, elige Guardar",
                "El reloj vuelve al menú de acciones de la plantilla guardada. Elige Usar plantilla para preparar el partido con esos ajustes.",
            ),
            (
                "serve",
                ('read', 130, 150),
                "Comprueba la configuración",
                "En Primer saque verás el formato y, debajo, la regla de iguales o Anotar · Solo juegos. Elige la pareja que saca y pulsa START cuando quieras empezar.",
            ),
        ],
        "tip": "Al poner un nombre, usa también Guardar en la última fila de Crear o Editar para registrar la plantilla completa.",
    },
    {
        "title": "Edita o elimina una plantilla",
        "intro": "Abre Plantillas y selecciona la que quieras gestionar, incluidas las que trae la app.",
        "steps": [
            (
                "template_actions",
                (130, 130),
                "Elige Editar para cambiarla",
                "Se abre el editor con los ajustes que ya tiene la plantilla. Haz los cambios y baja hasta Guardar para actualizarla.",
            ),
            (
                "template_actions",
                (130, 176),
                "Elige Eliminar para quitarla",
                "El reloj muestra ¿Eliminar? y vuelve a mostrar el nombre de la plantilla debajo de la opción Eliminar.",
            ),
            (
                "delete",
                (130, 153),
                "Comprueba el nombre y confirma",
                "Selecciona Eliminar para quitar la plantilla de la lista. Elige Cancelar o pulsa BACK para volver al menú de acciones.",
            ),
        ],
        "tip": "Si borras todas las de la lista, al volver verás Sin plantillas con Manual y Nueva plantilla.",
    },
]
