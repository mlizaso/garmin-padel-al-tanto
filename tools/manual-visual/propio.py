def pagina(titulo, intro, pasos, nota):
    return {"title": titulo, "intro": intro, "steps": pasos, "tip": nota}


mapa = pagina("Encuentra los cinco botones",
    "Sujeta el reloj con START arriba a la derecha. A la izquierda tienes tres botones. A la derecha, dos.",
    [
        ("play30", ("controls",), "Localiza cada botón con el reloj en la mano",
         "A la izquierda, LIGHT ilumina la pantalla. UP/MENU y DOWN sirven para subir y bajar por una lista. A la derecha, START/STOP, arriba, abre la opción elegida. BACK/LAP, abajo, vuelve desde un submenú. En el marcador, BACK deshace la última anotación."),
    ], "Desde la esfera de Garmin, pulsa START, busca Padel al Tanto con UP o DOWN y pulsa START otra vez. En el inicio verás Jugar, Plantillas y Ajustes (Play, Templates y Settings en inglés).")

inicio = pagina("Qué elegir al abrir Padel al Tanto",
    "Al entrar, busca la fila que necesitas. Estos tres accesos están en la pantalla de inicio.",
    [
        ("home", (130,83), "Jugar · Empieza un partido",
         "En Jugar, elige una plantilla o configura el partido en Manual. Después elige quién saca y confirma para empezar a grabar."),
        ("home", ("touch",130,122,(56,13)), "Plantillas · Gestiona tus formatos",
         "Entra aquí para crear, editar o eliminar configuraciones. Las que guardes estarán disponibles en Jugar."),
        ("home", ("touch",130,161,(47,13)), "Ajustes · Preferencias de la app",
         "Desde esta opción puedes cambiar el táctil o el idioma y activar la detección de golpes. BACK regresa al inicio."),
    ], "Si ya guardaste una actividad con anotaciones, verás también «Última sesión». Con los toques activos puedes abrir cualquier opción tocando su fila.")

idioma = pagina("Cambia el idioma de la aplicación",
    "En el inicio, abre Ajustes (Settings en inglés). En pleno partido, pulsa START y elige Ajustes.",
    [
        ("settings_language", ("touch",130,122,(91,14)), "Abre Idioma",
         "Toca Idioma (Language en inglés). Con botones, usa UP o DOWN para seleccionarla y pulsa START."),
        ("language_es", ("touch",130,148,(45,14)), "Elige Español o English",
         "Toca el idioma para aplicarlo. Con botones, selecciona con UP o DOWN y confirma con START."),
        ("home_en", None, "Vuelve con BACK",
         "El cambio es inmediato y ya se ve en Ajustes. Pulsa BACK para regresar al inicio. En este ejemplo, el inicio aparece en inglés."),
    ], "Por defecto, la app usa español si el reloj está en español e inglés con cualquier otro idioma. Tu elección se guarda.")

bloquear = pagina("Desactiva el táctil en pleno partido",
    "Prueba con un 30–30. El marcador y la grabación siguen en marcha mientras abres Ajustes.",
    [
        ("play30_strokes_off", "START", "Abre el menú con START",
         "Desde el marcador, pulsa una vez el botón superior derecho. También puedes tocar «Menú» al pie de la esfera."),
        ("match_menu", "START", "Entra en Ajustes con START",
         "Ajustes es la primera opción y al entrar ya está resaltada. Pulsa otra vez el botón superior derecho."),
        ("enabled", ("touch",130,83,(95,14)), "Toca la fila Pantalla táctil",
         "El estado pasa de «Sí» a «No». También puedes cambiarlo con START sobre esa fila. A partir de aquí usa los botones físicos."),
    ], "Pulsa BACK dos veces para regresar al marcador. Los signos − desaparecen y puedes seguir anotando con los botones.")

activar = pagina("Reactiva el táctil solo con botones",
    "Si faltan los signos − del marcador, puedes reactivar el táctil de la app con tres pulsaciones de START.",
    [
        ("blocked", "START", "Primera pulsación · Abre el menú",
         "Pulsa el botón superior derecho. El partido sigue grabándose aunque la pantalla ignore los toques."),
        ("match_menu", "START", "Segunda pulsación · Abre Ajustes",
         "Pulsa START sobre Ajustes. La fila «Pantalla táctil» aparece seleccionada y su estado es «No»."),
        ("disabled", "START", "Tercera pulsación · Activa el táctil",
         "Pulsa START sobre «Pantalla táctil» y lee «Sí». Regresa al marcador con dos pulsaciones de BACK y verás los signos − de nuevo."),
    ], "Suelta START entre las tres pulsaciones. Una cuarta pulsación, si sigues en Ajustes, vuelve a desactivar el táctil. La preferencia se conserva al cerrar la app.")

gesto = pagina("Deshaz un punto deslizando el dedo",
    "Este ejemplo empieza en 30–30. Rivales, la pareja de abajo, acaba de ganar el último punto.",
    [
        ("play30", ("read",36,85,(17,17)), "Busca el signo − junto al tanteo",
         "Los signos − indican que el táctil de la app está activo. Si faltan, sigue la página anterior para activarlo."),
        ("play30", ("left",), "Arrastra del borde derecho al izquierdo",
         "Apoya el dedo dentro del borde derecho de la esfera y, sin levantarlo, cruza el marcador hacia la izquierda. Levántalo al final."),
        ("play15", ("read",102,173), "Comprueba que Rivales baja a 15",
         "Queda 30–15. Nosotros sigue sacando arriba y mantiene su 30. Un segundo deslizamiento desharía otra anotación."),
    ], "En un submenú, el gesto vuelve una pantalla. Desde el inicio sale de la app. En el teclado cancela la edición del nombre. El gesto inverso también equivale a BACK.")

atajos = pagina("Atajos para moverte sin perder el tanteo",
    "Antes de pulsar, mira si estás en un menú, en el marcador o en una pantalla de cierre.",
    [
        ("play30", "MENU", "Mantén UP/MENU para abrir Ajustes",
         "Desde el marcador, el inicio o Primer saque, mantén pulsado el botón central izquierdo. Cuando entras por este atajo, un solo BACK te devuelve al origen."),
        ("library", ("buttons",["UP","DOWN"]), "Recorre las listas",
         "Pulsa UP o DOWN para moverte una fila. Con el táctil activo, desliza hacia arriba para bajar en la lista. En el marcador, el gesto vertical conserva el tanteo."),
        ("match_over", "UP", "Abre Historial al terminar",
         "En «Partido terminado» o «Ronda cerrada», UP o MENU abren el historial. En el resumen ya guardado, hazlo con START o MENU."),
    ], "En el marcador, una pulsación corta de UP suma a la pareja al saque. Para entrar en Ajustes con pulsaciones cortas, usa START y después START.")

evitar = pagina("Tres pulsaciones que conviene evitar",
    "La cruz roja marca el control que cambiaría el resultado o terminaría la actividad en estas situaciones.",
    [
        ("play30", ("avoid","BACK"), "Para consultar, evita BACK",
         "Desde el marcador, BACK quita la última anotación. Si solo quieres comprobar quién puntuó, toca «Historial» o búscalo con START."),
        ("play30", ("avoid",36,85), "Para sumar, evita el signo menos",
         "El pequeño − a la izquierda resta a esa pareja. Si ganó el punto, toca una sola vez el número grande de su fila."),
        ("confirm", ("avoid","START"), "Para seguir, evita START aquí",
         "En «¿Terminar?», START inicia el guardado. Para seguir jugando, pulsa BACK o toca «Seguir jugando»."),
    ], "Cuando el táctil está bloqueado, los botones siguen activos. Mira «SAQUE» antes de usar UP, porque las parejas cambian de fila al cambiar el servicio.")

sensores = pagina("Activa la detección de golpes",
    "La detección de golpes está desactivada por defecto. El reloj muestra el pulso durante la actividad cuando hay datos.",
    [
        ("strokes_off", ("touch",130,161,(123,14)), "Selecciona Detección de golpes",
         "Desde el inicio, abre Ajustes. Durante el partido, pulsa START y elige Ajustes. Baja con DOWN hasta la tercera fila."),
        ("strokes_on", ("read",130,161,(123,14)), "Cambia el ajuste a «Sí»",
         "Pulsa START sobre esa fila o tócala con la pantalla táctil activa. El reloj recuerda tu elección para las próximas sesiones."),
        ("play30", ("read",161,26,(41,10)), "Consulta los golpes en el marcador",
         "Lleva el reloj en la muñeca de la pala. «~-- golpes» aparece mientras faltan muestras. El recuento puede incluir gestos sin pelota u omitir algún golpe."),
    ], "Si desactivas la detección durante el partido, se conserva el recuento acumulado hasta ese momento y el pulso sigue disponible.")

vibracion = pagina("Reconoce la vibración sin mirar",
    "La app elige la vibración según lo que acaba de cerrarse. Puedes reconocerla en la muñeca mientras juegas.",
    [
        ("play40", ("read",107,84), "Un pulso corto · Punto",
         "Un punto normal da un pulso corto. Al ganar un juego sentirás uno más largo, salvo cuando ese juego también cierre la ronda, el set o el partido."),
        ("round_over", ("read",128,99), "Dos pulsos iguales · Ronda",
         "En americano, dos pulsos de la misma duración indican que se ha alcanzado el total de juegos de esa ronda."),
        ("match_over", ("read",129,114), "Dos distintos · Set / tres · Partido",
         "Un pulso corto seguido de uno largo marca un set. Cuando la pareja ganadora completa el partido, el reloj emite tres pulsos."),
    ], "La app aplica estos patrones automáticamente. Comprueba cómo se sienten en el reloj físico durante un juego de prueba.")

ayuda = pagina("Si el reloj no responde como esperabas",
    "Identifica primero qué pantalla ves. El aviso «Sin espacio» se ha reproducido en el simulador para esta guía.",
    [
        ("enabled", ("read",130,83,(95,14)), "La fila dice «Sí» y faltan los toques",
         "Desde la esfera de Garmin, mantén MENU y abre Sistema > Táctil. Comprueba que esté permitido durante la actividad. En Padel al Tanto puedes usar los botones en todo momento."),
        ("serve", "START", "Si aparece «Error al iniciar»",
         "Comprueba que puedes iniciar una actividad y que hay espacio en el reloj. Vuelve a Primer saque y pulsa START sobre Iniciar. Espera a ver el marcador antes de anotar."),
        ("storage_full", (130,130), "Si al editar sale «Sin espacio»",
         "Toca Volver o pulsa BACK. Revisa la lista de plantillas. Si has llegado al límite, puedes quitar una que ya no uses y volver a guardar."),
    ], "Si el aviso dice «Error al guardar» al finalizar una actividad, hay una pantalla específica para reintentar el guardado. La encontrarás en el índice.")

instalar = pagina("Abrir el simulador o instalar por USB",
    "Usa el código fuente para practicar en el simulador o descarga el ZIP de instalación para tu reloj.",
    [
        ("play30", ("buttons",["UP","DOWN"]), "Practica en el simulador",
         "Instala el SDK Connect IQ y la extensión Monkey C. Abre PadelAlTanto y un archivo .mc en Visual Studio Code. Ejecuta sin depurar y elige fēnix 7 o 7 Pro."),
        ("home", None, "Por USB · Elige tu modelo",
         "Descomprime el ZIP. Para el fēnix 7 Pro de 47 mm usa fenix7pro/PADELAT.PRG. Para el fēnix 7 estándar de 47 mm usa PADELAT.PRG de la carpeta principal."),
        ("home", "START", "Copia el archivo y abre Padel al Tanto",
         "Con un cable de datos, copia el PRG a GARMIN/APPS del reloj. Espera a que termine, desconecta y, desde la esfera, pulsa START. Busca Padel al Tanto y ábrela."),
    ], "Si actualizas una instalación manual, guarda una copia del PRG anterior y usa su nombre de archivo al reemplazarlo para conservar tus ajustes. En Windows abre el reloj en el Explorador. En Mac, cierra Garmin Express antes de abrir el cliente MTP.")

connect = pagina("Consulta la actividad en Garmin Connect",
    "El archivo FIT contiene el tiempo, el resultado y el pulso disponible. Si activaste la detección y hubo muestras válidas, incluye el recuento estimado de golpes.",
    [
        ("confirm", "START", "Guarda y espera el resumen",
         "En «¿Terminar?», pulsa START. Espera hasta que veas «Partido guardado» o «Sesión guardada»."),
        ("saved", ("read",128,123), "Sincroniza el reloj",
         "Abre Garmin Connect, sincroniza tu reloj y entra en la actividad de pádel. Allí puedes consultar la duración y, si hubo muestras, la curva del pulso."),
        ("saved_round_partial", ("read",129,162), "Recupera parciales y datos de golpes",
         "En el FIT, un asterisco marca un parcial incompleto. Si Connect oculta los campos propios de la app, usa «Exportar original» en Garmin Connect web."),
    ], "En un americano, el FIT conserva las rondas en orden. Si no caben todos los parciales en el campo de texto, verás los más recientes precedidos por «…».")
