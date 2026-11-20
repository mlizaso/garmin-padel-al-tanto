#!/usr/bin/env python3
"""Monta en orden las capturas del simulador de las primeras versiones de Padel al Tanto."""

import argparse
import json
from base64 import b64encode
from html import escape
from pathlib import Path
from string import Template
from urllib.parse import quote


PAGE = Template("""<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Padel al Tanto en el simulador</title>
  <style>
    :root {
      color-scheme: light;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.5;
      color: #182922;
      background: #f0f5f2;
    }
    * { box-sizing: border-box; }
    body {
      max-width: 81rem;
      margin: 0 auto;
      padding: clamp(1rem, 4vw, 3rem);
    }
    header { margin-bottom: clamp(1.25rem, 4vw, 2.5rem); }
    header p { margin: 0 0 .35rem; color: #486259; }
    h1 {
      margin: 0;
      font-size: clamp(1.8rem, 4vw, 3rem);
      line-height: 1.15;
      letter-spacing: -.025em;
    }
    section + section { margin-top: 2.5rem; }
    .section-title { margin: 0 0 .85rem; font-size: 1.35rem; }
    .steps {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(min(100%, 20rem), 1fr));
      gap: 1.25rem;
      margin: 0;
      padding: 0;
      list-style: none;
    }
    article {
      height: 100%;
      background: #fff;
      border: 1px solid #cbdad2;
      border-radius: 1rem;
      overflow: hidden;
    }
    article h2, article h3 {
      display: flex;
      gap: .75rem;
      align-items: baseline;
      margin: 0;
      padding: 1rem 1.1rem;
      font-size: 1.075rem;
      line-height: 1.35;
      overflow-wrap: anywhere;
    }
    .step { color: #197050; font-variant-numeric: tabular-nums; }
    .capture {
      display: grid;
      place-items: center;
      min-height: 13rem;
      padding: .75rem;
      background: #17221e;
    }
    .capture:focus-visible {
      outline: 3px solid #70e8b4;
      outline-offset: -4px;
    }
    img {
      display: block;
      width: auto;
      height: auto;
      max-width: 100%;
      max-height: 22rem;
    }
    dl { margin: 0; padding: 1rem 1.1rem 1.2rem; }
    dt { font-weight: 650; }
    dd {
      margin: .12rem 0 0;
      color: #43554c;
      overflow-wrap: anywhere;
      white-space: pre-line;
    }
    dd + dt { margin-top: .7rem; }
  </style>
</head>
<body>
  <header>
    <p>Garmin fēnix 7 · Simulador Connect IQ</p>
    <h1>Padel al Tanto en el simulador</h1>
    <p>Consulta los menús y controles en el <a href="../Manual-visual-Padel-al-Tanto.pdf">manual ilustrado</a>.</p>
  </header>
  <main>
    <section aria-labelledby="idioma">
      <h2 id="idioma" class="section-title">Cambiar el idioma</h2>
      <p>Antes de elegir, la app usa español si el reloj está en español e inglés con cualquier otro idioma del reloj. La app recuerda el idioma que elijas.</p>
      <ol class="steps" role="list">
        <li>
          <article>
            <h3>Abre Ajustes e Idioma</h3>
            <a class="capture" href="v07/01-ajustes.png">
              <img src="v07/01-ajustes.png" alt="Ajustes en español con la fila Idioma seleccionada" width="260" height="260">
            </a>
          </article>
        </li>
        <li>
          <article>
            <h3>Elige Español o English</h3>
            <a class="capture" href="v07/02-idioma.png">
              <img src="v07/02-idioma.png" alt="Menú Idioma con las opciones Español y English" width="260" height="260">
            </a>
          </article>
        </li>
        <li>
          <article>
            <h3>Vuelve al inicio con BACK</h3>
            <a class="capture" href="v07/03-inicio-en.png">
              <img src="v07/03-inicio-en.png" alt="Inicio de Padel al Tanto en inglés con Play, Templates y Settings" width="260" height="260">
            </a>
          </article>
        </li>
      </ol>
    </section>
    <section aria-labelledby="marcador">
      <h2 id="marcador" class="section-title">Marcador en español e inglés</h2>
      <ul class="steps">
        <li>
          <article>
            <h3>Español</h3>
            <a class="capture" href="v07/04-marcador-es.png">
              <img src="v07/04-marcador-es.png" alt="Marcador 30–30 en español, con Nosotros al saque" width="260" height="260">
            </a>
          </article>
        </li>
        <li>
          <article>
            <h3>English</h3>
            <a class="capture" href="v07/05-marcador-en.png">
              <img src="v07/05-marcador-en.png" alt="El mismo 30–30 en inglés, con Us al saque" width="260" height="260">
            </a>
          </article>
        </li>
      </ul>
    </section>
    <section aria-labelledby="archivo">
      <h2 id="archivo" class="section-title">Primeras versiones</h2>
$gallery
    </section>
  </main>
</body>
</html>
""")

CARD = Template("""      <li>
        <article>
          <h2><span class="step" aria-hidden="true">$index</span><span>$title</span></h2>
          <a class="capture" href="$url" aria-label="Ver captura completa de «$title»">
            <img src="$preview" alt="Captura del simulador, $title" loading="$loading">
          </a>
          <dl>
            <dt>Acción</dt>
            <dd>$action</dd>
            <dt>Resultado</dt>
            <dd>$detail</dd>
          </dl>
        </article>
      </li>""")


def render_gallery(frames, destination):
    if not isinstance(frames, list):
        raise ValueError("El JSON debe contener una lista de capturas.")

    gallery_dir = destination.parent.resolve()
    cards = []
    for index, frame in enumerate(frames, start=1):
        if not isinstance(frame, dict):
            raise ValueError(f"La captura {index} debe ser un objeto.")
        for field in ("file", "title", "action", "detail"):
            value = frame.get(field)
            if not isinstance(value, str) or not value.strip():
                raise ValueError(f"La captura {index} necesita el campo de texto {field}.")

        capture = Path(frame["file"])
        source = (gallery_dir / capture).resolve()
        if capture.is_absolute() or ".." in capture.parts or not source.is_relative_to(gallery_dir):
            raise ValueError(f"La captura {index} debe estar dentro de la carpeta de la galería.")
        if not source.is_file():
            raise ValueError(f"No se encuentra el archivo «{capture}» de la captura {index}.")

        url = quote(capture.as_posix())
        preview = url
        if capture.suffix.lower() == ".png":
            preview = f"data:image/png;base64,{b64encode(source.read_bytes()).decode('ascii')}"
        cards.append(CARD.substitute(
            index=index,
            title=escape(frame["title"]),
            url=url,
            preview=preview,
            loading="eager" if index <= 3 else "lazy",
            action=escape(frame["action"]),
            detail=escape(frame["detail"]),
        ))

    if not cards:
        return '    <p>Aún no hay capturas.</p>'
    return '    <ol class="steps" role="list">\n' + "\n".join(cards) + "\n    </ol>"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("frames", type=Path, help="JSON con file, title, action y detail")
    parser.add_argument("html", type=Path, help="Archivo HTML de salida")
    args = parser.parse_args()

    try:
        frames = json.loads(args.frames.read_text(encoding="utf-8"))
        page = PAGE.substitute(gallery=render_gallery(frames, args.html))
        args.html.parent.mkdir(parents=True, exist_ok=True)
        args.html.write_text(page, encoding="utf-8")
    except (OSError, ValueError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
