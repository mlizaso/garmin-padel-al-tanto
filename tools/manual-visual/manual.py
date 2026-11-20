from argparse import ArgumentParser
from pathlib import Path
from propio import (
    activar, atajos, ayuda, bloquear, connect, evitar, gesto, idioma, inicio,
    instalar, mapa, pagina, sensores, vibracion,
)
from partido import pages as partido
from plantillas import pages as plantillas
from layout import FONTS, build


americano = pagina("Juega un americano a seis juegos",
    "Una ronda de seis juegos puede acabar 6–0, 5–1, 4–2 o 3–3. Cuenta el total disputado por las dos parejas.",
    [
        ("serve_americano", ("read",130,151), "Revisa el formato al empezar",
         "Aquí pone «Americano · 6 juegos» y «Anotar · Solo juegos». Elige el primer saque y pulsa START. En Cada punto también puedes jugar un americano."),
        ("americano_play", ("read",130,130), "Mira cuántos juegos faltan",
         "La línea central dice «Ronda 1 · 5/6 juegos». Nosotros lleva tres y Rivales dos. Falta un solo juego para cerrar la ronda."),
        ("americano_play", (101,85), "Anota el sexto juego",
         "Si lo gana Rivales, toca su 2, en la fila de arriba, o pulsa UP. La ronda queda 3–3. Si lo gana Nosotros, toca su 3 abajo y queda 4–2."),
    ], "Puedes elegir cualquier total de 1 a 99. Al cambiar de compañero, empieza una nueva ronda dentro de la misma actividad para seguir grabando el tiempo y el pulso.")


sections = [
    ("Primeros pasos", [mapa, inicio, idioma, partido[0]]),
    ("Táctil y botones", [bloquear, activar, gesto, atajos, evitar]),
    ("El marcador", [partido[i] for i in (1,2,3,4,5,7,8,9)]),
    ("Plantillas y reglas", plantillas),
    ("Americano", [americano, partido[10], partido[11]]),
    ("Guardar y consultar", [partido[i] for i in (12,13,15,16,6)]),
    ("Actividad y ayuda", [sensores, vibracion, connect, partido[14], ayuda, instalar]),
]
pages = [dict(page, section=section) for section, group in sections for page in group]

if __name__ == "__main__":
    root = Path(__file__).parent
    parser = ArgumentParser(description="Genera el manual visual de Padel al Tanto.")
    parser.add_argument("destino", nargs="?", default=root.parents[1] / "Manual-visual-Padel-al-Tanto.pdf", type=Path)
    parser.add_argument("--font-dir", default=FONTS, type=Path, help="Carpeta con las fuentes Arial")
    args = parser.parse_args()
    build(pages, root / "shots", args.destino, font_dir=args.font_dir)
    print(f"{len(pages)} páginas de instrucciones, {sum(len(p['steps']) for p in pages)} tarjetas, "
          f"{len({step[0] for p in pages for step in p['steps']})} capturas distintas.")
