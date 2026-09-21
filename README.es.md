<div align="center">

# Control Systems and Automation

**Prácticas de laboratorio en MATLAB para Automatización Industrial — Identificación de Sistemas y Análisis de Control**

[![idioma](https://img.shields.io/badge/lang-Espa%C3%B1ol-blue)](#) [![English](https://img.shields.io/badge/English-README.md-green)](README.md)

![MATLAB](https://img.shields.io/badge/MATLAB-R2022b-informational)
![Control System Toolbox](https://img.shields.io/badge/Toolbox-Control%20System-blue)
![Identificación de sistemas](https://img.shields.io/badge/M%C3%A9todo-Identificaci%C3%B3n%20de%20Sistemas-purple)
![Respuesta en frecuencia](https://img.shields.io/badge/An%C3%A1lisis-Respuesta%20en%20Frecuencia-orange)
![Diagramas de Bode](https://img.shields.io/badge/Plots-Diagramas%20de%20Bode-teal)
![Académico](https://img.shields.io/badge/Objetivo-Acad%C3%A9mico-brightgreen)

</div>

Prácticas de laboratorio en **MATLAB** de la asignatura *Automatización Industrial* de la **UNED** (Universidad Nacional de Educación a Distancia). En cada práctica se identifica la función de transferencia de un sistema analógico real a partir de respuestas al escalón y capturas de frecuencia medidas, y se valida el modelo frente a los datos.

## Resumen

Cada carpeta de práctica contiene los **datos medidos** (capturas del osciloscopio), los **scripts MATLAB** que realizan la identificación y las **figuras** (`.fig` y `.png`) empleadas en el informe escrito.

| Práctica | Sistema analizado | Contenido |
|---|---|---|
| **FAa-08** | Sistema de primer orden con cero (red de adelanto) `G(s) = K(1+Ts)/(1+τs)` | Obtención de la constante de tiempo `τ` y del cero `T` a partir del escalón; Bode (módulo y fase) frente a puntos experimentales; márgenes de ganancia y fase; ajuste de un modelo temporal `G(t)` frente a un modelo identificado en frecuencia `G(f)` |
| **FBa-08** | Sistema de segundo orden subamortiguado `G(s) = K·ωₙ²/(s²+2ζωₙs+ωₙ²)` | Especificaciones temporales (`Mp`, `t_p`, `t_d`, `t_r`, `t_s`, `ζ`, `ω_d`, `ω_n`); pico de resonancia `fr`/`Mr`; diagramas de Bode anotados; comparación `G(t)` vs `G(f)` |
| **FCa-16** | Sistema de segundo orden subamortiguado | El mismo flujo completo aplicado a un segundo dataset |

> Los scripts `G(t)` vs `G(f)` construyen dos modelos por sistema: uno identificado en el **dominio del tiempo** (respuesta al escalón) y otro ajustado en el **dominio de la frecuencia** (mínimos cuadrados sobre el módulo en dB), y comparan ambos con las medidas de laboratorio.

### Vista previa

| Respuesta al escalón y ajuste del modelo | Bode anotado (módulo) | Comparación de escalón `G(t)`/`G(f)` |
|---|---|---|
| ![Respuesta al escalón FBa-08](practices/FBa-08/figures/MATLAB_RespuestaEscalon.png) | ![Bode anotado FAa-08](practices/FAa-08/figures/MATLAB_ModuloBode_Anotado.png) | ![Comparación de escalón FCa-16](practices/FCa-16/figures/MATLAB_ComparacionEscalon.png) |

## Estructura del repositorio

```text
.
├── README.md                              # Versión en inglés
├── README.es.md                           # Este archivo
├── docs/
│   └── Guion_Practicas_AI.pdf             # Guión de la asignatura
├── practices/
│   ├── FAa-08/
│   │   ├── code/                          # Scripts MATLAB (.m)
│   │   ├── data/                          # Capturas del osciloscopio (.csv)
│   │   └── figures/                       # Gráficas (.fig y .png)
│   ├── FBa-08/
│   │   └── ...
│   └── FCa-16/
│       └── ...
└── report/
    ├── AI-Soriano_Palacios_Maria.pdf      # Informe completo (PDF)
    └── AI-Soriano_Palacios_Maria.docx     # Informe editable (Word)
```

Cada carpeta de práctica sigue la misma estructura:

```text
FAa-08/
├── code/      # FAa08_MATLAB.m  +  FAa08_MATLAB_ComparacionFinal.m
├── data/      # FAa-08_Waveform.csv  (tiempo, CH1 entrada, CH2 salida)
└── figures/   # Bode (módulo y fase), respuesta al escalón, tau y resonancia
```

## Cómo empezar

### Requisitos

- **MATLAB** (R2019b o superior) con **Control System Toolbox** (`tf`, `bode`, `margin`, `lsim`).
- Los ficheros `.csv` de waveforms (ya incluidos en `data/`).

### Ejecución de los scripts

1. Abre `code/` en MATLAB y añade la carpeta `data/` al path (o ejecuta desde una carpeta que contenga ambos — los scripts leen el `.csv` por nombre de archivo).
2. Ejecuta el script principal, p. ej. `FAa08_MATLAB.m`, y después el de las figuras finales `FAa08_MATLAB_ComparacionFinal.m`.
3. Los parámetros identificados y los márgenes de estabilidad se imprimen en la ventana de comandos.

```matlab
% Ejemplo: FAa-08 (sistema de primer orden con cero)
run FAa08_MATLAB.m
```

## Conceptos cubiertos

- Funciones de transferencia y modelado en el dominio de Laplace
- Respuesta en frecuencia: diagramas de Bode de módulo y fase
- Márgenes de fase y ganancia, análisis de estabilidad
- Identificación de sistemas a partir de la respuesta al escalón (constante de tiempo, sobreoscilación/ζ)
- Dinámica de segundo orden: `ζ`, `ωₙ`, tiempos de subida y establecimiento, resonancia `Mr`
- Validación de modelos: modelo temporal frente a ajuste en frecuencia
- Fundamentos de automatización industrial

## Habilidades desarrolladas

- Programación en MATLAB y Control System Toolbox
- Modelado matemático de sistemas reales medidos en hardware
- Validación de ingeniería basada en simulación
- Análisis cuantitativo de estabilidad y prestaciones dinámicas

## Acerca de

Desarrollado por **María Soriano Palacios** como parte del grado en **Ingeniería Electrónica Industrial y Automática** en la UNED. Los scripts conservan comentarios y notación en español, acordes con el idioma de la asignatura.

*Trabajo académico publicado como portfolio de habilidades en control y automatización.*