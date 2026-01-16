# MiKitOCRDemo

# 🌟 Descripción

Proyecto  realizado en el taller
"Acceso al LLM mediante componentes de tipo Chat".

Curso "Microcredencial Implementación y uso de IA generativa en Delphi".


La intención es que sirva de semilla para el desarrollo de diferentes
herramientas y complementos para  MakerAI. Usando MakerAi, Pdfium4D, y algo más.

* Creacion y registro de nuevos motortes TAiChat. Usando G4F (Chat4Free).
* Delegación entre modelos. Delega pdftool de un proveedor para usar el ocr vision de otro modelo.
* Uso de  Pdfium para extraer imagenes de un pdf (Probado en Windows64 y Android64).

Aunque tiene dependencias minimas, necesitas MakerAI y los binarios de pdfium
https://github.com/bblanchon/pdfium-binaries/releases


## KitMaker Sample

Selecciona los modelos a usar.

* Driver LLM : Es el motor y modelo usado para hacer el chat.
* Driver OCR: Es el motor y modelo usado para hacer el OCR.

  ![Kit screenshot](imagenes/Config.png)

Selecciona el archivo a adjuntar en chat

  ![Kit screenshot](imagenes/chat.png)

Realiza OCR directo

  ![Kit screenshot](imagenes/directo.png)


#  Instalacion

## MITPackMakerAI

Compila  MITPackMakerAI.dpk, para instalar los nuevos componentes.

## uMakerAi.Chat.G4F

* Registra varios proveedores de acceso abierto aunque limitado.
* TAiG4FOllama,TAiG4FPollinations,TAiG4FNvidia,TAiG4FGroqChat,TAiG4FGemini
* https://github.com/xtekky/gpt4free
* https://g4f.dev/



##  uMakerAI.Ollama.PdfIUM

Es una modificacion de la idea original  uMakerAI.Ollama.Pdf.

* TAiOllamaPdfIUMTool.

Usa la libreria pdfium.dll para extraer las imagenes de los pdf.
** libpdfium.so em Amdroid


* TAiDelegaOcrTool ,

Parecido a TAiOllamaOcrTool, pero delegando el OCR a  otro TAiChatConnection.

## DX.Pdf.Dynamic y KitMaker.Pdf.Extractor

Es una adaptacion del proyecto https://github.com/omonien/DX-Pdfium4D,
para usar la libreria   pdfium.dll de forma dinamica en lugar de
estaticamente del proyecto original.

https://github.com/bblanchon/pdfium-binaries/releases


## Futuro

* Integrar librerias python como PyPDF2.
* Integrar Voz.
* MCP
* Orquestacion
