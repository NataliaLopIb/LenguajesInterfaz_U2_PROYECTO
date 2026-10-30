[README.md](https://github.com/user-attachments/files/34194569/README.md)
# Proyecto U2 - Sistema de Ventas e Inventario (Glamour Makeup Sinaloa)

- **Materia:** Lenguajes de Interfaz - Unidad 2
- **Alumna:** Natalia Lopez Ibarra y Frida Sofia Vega Vazquez
- **Horario:** 9am-10am y 8am-9am
- **Docente:** Dr. Jose Luis Medina Jimenez

Programa de consola en ensamblador x86 de 32 bits (MASM) con la libreria Irvine32. Administra el inventario y las ventas de una tienda de maquillaje: hasta 10 productos, importes en centavos enteros y salida en MXN. Regla adicional: 10% de descuento en ventas de 3 o mas unidades (mayoreo).

## Archivos
| Archivo | Descripcion |
| `main.asm` | Programa completo |
| `InventarioMaquillaje.txt` | Inventario de prueba (4 productos), archivo de texto |
| `Informe.md` | Negocio, regla adicional, memoria, formato de archivo, decisiones y fuentes |
| `TablaPruebas.md` | Entrada / resultado esperado / resultado obtenido |
| `GuionDemostracion.md` | Pasos de la demostracion y recorrido en el depurador |
| `GuiaDefensa.md` | Respuestas a las 12 preguntas de revision con referencias al codigo |

## Menu
1. Registrar Producto  2. Consultar Inventario  3. Buscar por Codigo  4. Recibir Mercancia  5. Vender Producto  6. Mostrar Resumen  7. Guardar  8. Salir (pregunta S/N si hay cambios sin guardar)

## Compilacion (Visual Studio 2022 + plantilla Irvine32 de la clase)
1. Abre el proyecto Irvine32 que usas en clase (el que ya compila tus practicas) y reemplaza el `.asm` por `main.asm`.
2. Plataforma **x86 (Win32)**, Debug.
3. Compila y ejecuta (Ctrl+F5).
4. Copia `InventarioMaquillaje.txt` a la **carpeta del proyecto** (la que contiene el `.vcxproj`; es el directorio de trabajo con el que VS ejecuta). Si lo ejecutas desde la carpeta `Debug`, copialo ahi.

## Formato del archivo de inventario
Texto plano: primera linea `GLM1` y una linea por producto con `CODIGO;NOMBRE;PRECIO;EXISTENCIA`:
```
GLM1
LAB-101;Labial Mate Rojo;189.50;25
```

## Pruebas rapidas
- **Archivo ausente:** borra o renombra el `.txt` y ejecuta.
- **Archivo invalido:** abrelo con el Bloc de notas y cambia `GLM1` de la primera linea, pon un precio como `12.555`, repite un codigo o borra un `;`; guarda y ejecuta.
