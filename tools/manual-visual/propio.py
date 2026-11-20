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
         "Elige Jugar para preparar el primer saque. El reloj empieza a grabar cuando confirmes el inicio en la pantalla siguiente."),
        ("home", ("touch",130,122,(56,13)), "Plantillas · Elige cómo puntuar",
         "Entra aquí para elegir sets o americano, punto de oro, ventajas o Solo juegos. Puedes guardar tus combinaciones con un nombre."),
        ("home", ("touch",130,161,(47,13)), "Ajustes · Cambia el táctil o el idioma",
         "En Ajustes, selecciona Pantalla táctil para permitir toques o Idioma para cambiar el texto de la app. BACK regresa al inicio."),
    ], "Si ya guardaste una actividad con anotaciones, verás también «Última sesión». Con los toques activos puedes abrir cualquier opción tocando su fila.")

idioma = pagina("Cambia el idioma de la aplicación",
    "En el inicio, abre Ajustes (Settings en inglés). En pleno partido, pulsa START y elige Ajustes.",
    [
        ("settings_language", ("touch",130,169,(91,14)), "Abre Idioma",
         "Toca Idioma (Language en inglés). Con botones, usa UP o DOWN para seleccionarla y pulsa START."),
        ("language_es", ("touch",130,148,(45,14)), "Elige Español o English",
         "Toca el idioma para aplicarlo. Con botones, selecciona con UP o DOWN y confirma con START."),
        ("home_en", None, "Vuelve con BACK",
         "El cambio es inmediato y ya se ve en Ajustes. Pulsa BACK para regresar al inicio. En este ejemplo, el inicio aparece en inglés."),
    ], "Por defecto, la app usa español si el reloj está en español e inglés con cualquier otro idioma. Tu elección se guarda.")

bloquear = pagina("Desactiva el táctil en pleno partido",
    "Prueba con un 30–30. El marcador y la grabación siguen en marcha mientras abres Ajustes.",
    [
        ("play30", "START", "Abre el menú con START",
         "Desde el marcador, pulsa una vez el botón superior derecho. También puedes tocar «Menú» al pie de la esfera."),
        ("match_menu", "START", "Entra en Ajustes con START",
         "Ajustes es la primera opción y al entrar ya está resaltada. Pulsa otra vez el botón superior derecho."),
        ("enabled", ("touch",130,117,(95,14)), "Toca la fila Pantalla táctil",
         "El estado pasa de «Sí» a «No». También puedes cambiarlo con START sobre esa fila. A partir de aquí usa los botones físicos."),
    ], "Pulsa BACK dos veces, una para salir de Ajustes y otra para cerrar el menú. Verás «Táctil no». Los toques y los deslizamientos quedan bloqueados.")

activar = pagina("Reactiva el táctil solo con botones",
    "Empieza en el marcador donde pone «Táctil no». Para reactivarlo basta con tres pulsaciones de START.",
    [
        ("blocked", "START", "Primera pulsación · Abre el menú",
         "Pulsa el botón superior derecho. El partido sigue grabándose aunque la pantalla ignore los toques."),
        ("match_menu", "START", "Segunda pulsación · Abre Ajustes",
         "Pulsa START sobre Ajustes. La fila «Pantalla táctil» aparece seleccionada y su estado es «No»."),
        ("disabled", "START", "Tercera pulsación · Activa el táctil",
         "Pulsa START sobre «Pantalla táctil» y lee «Sí». Pulsa BACK dos veces para regresar al marcador. Abajo verás «Táctil sí»."),
    ], "Suelta START entre las tres pulsaciones. Una cuarta pulsación, si sigues en Ajustes, vuelve a desactivar el táctil. La preferencia se conserva al cerrar la app.")

gesto = pagina("Deshaz un punto deslizando el dedo",
    "Este ejemplo empieza en 30–30. Rivales, la pareja de abajo, acaba de ganar el último punto.",
    [
        ("play30", ("read",109,217), "Comprueba que dice Táctil sí",
         "Mira la línea pequeña bajo las dos cifras. Si pone «Táctil no», sigue la página anterior para activarlo."),
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

sensores = pagina("Lee el pulso y los golpes estimados",
    "Los dos datos de actividad aparecen en la cabecera del marcador. La grabación empieza al confirmar el primer saque.",
    [
        ("play30", ("read",85,26), "lpm · Pulsaciones por minuto",
         "Lleva el reloj ajustado con el sensor de muñeca en Auto o usa tu banda habitual. Dos guiones indican que aún faltan datos."),
        ("play30", ("read",167,26), "Golpes · Movimientos del brazo",
         "Lleva el reloj en la muñeca de la pala. El acelerómetro estima tus golpes. Puede contar un gesto sin pelota o pasar por alto una volea corta."),
        ("saved", ("read",130,164), "Consulta la estimación guardada",
         "El resumen muestra la estimación si hubo datos del sensor. En esta captura del simulador aparece «Golpes sin datos»."),
    ], "Para probarlo, mira el contador, da 20 golpes y compara el incremento. Los movimientos del brazo nunca suman puntos al marcador.")

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
        ("enabled", ("read",130,117,(95,14)), "La fila dice «Sí» y faltan los toques",
         "Desde la esfera de Garmin, mantén MENU y abre Sistema > Táctil. Comprueba que esté permitido durante la actividad. En Padel al Tanto puedes usar los botones en todo momento."),
        ("serve", "START", "Si aparece «Error al iniciar»",
         "Comprueba que puedes iniciar una actividad y que hay espacio en el reloj. Vuelve a Primer saque y pulsa START. Espera a ver el marcador antes de anotar."),
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
    "Al guardar, el reloj crea un archivo FIT de pádel con el tiempo de actividad y las muestras recogidas.",
    [
        ("confirm", "START", "Guarda y espera el resumen",
         "En «¿Terminar?», pulsa START. Espera hasta que veas «Partido guardado» o «Sesión guardada»."),
        ("saved", ("read",128,123), "Sincroniza el reloj",
         "Abre Garmin Connect, sincroniza tu reloj y entra en la actividad de pádel. Allí puedes consultar la duración y, si hubo muestras, la curva del pulso."),
        ("saved_round_partial", ("read",129,162), "Recupera parciales y datos de golpes",
         "En el FIT, un asterisco marca un parcial incompleto. Si Connect oculta los campos propios de la app, usa «Exportar original» en Garmin Connect web."),
    ], "En un americano, el FIT conserva las rondas en orden. Si no caben todos los parciales en el campo de texto, verás los más recientes precedidos por «…».")
