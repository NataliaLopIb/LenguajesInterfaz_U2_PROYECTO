# Informe - Proyecto Unidad 2

**Materia:** Lenguajes de Interfaz | **Alumna:** Natalia Lopez Ibarra, Frida Sofia Vega Vazquez **Docente:** Dr. Jose Luis Medina Jimenez

## 1. Negocio elegido
Tienda de maquillaje "Glamour Makeup Sinaloa": cosmeticos con codigo `ABC-123` (ej. `LAB-101` labial, `RIM-202` rimel).

## 2. Regla adicional: descuento por cantidad (mayoreo)
- **Cuando se aplica:** en una venta (un solo producto) de **3 o mas unidades**.
- **Calculo:** `descuento = importe_base / 10` (DIV entero, se descartan fracciones de centavo) y `importe_final = importe_base - descuento`.
- **Por que asi:** el PDF pide "descartar las fracciones de centavo al calcular los descuentos"; se trunca el monto del descuento. Dividir entre 10 evita multiplicar por 90 (que podria pasar de 32 bits con importes altos).
- **Caso que aplica:** 3 x RIM-202 (145.00) = 435.00 - 43.50 = **391.50 MXN**.
- **Caso que no aplica:** 2 x RIM-202 = **290.00 MXN**.
- **Truncamiento:** 3 x BAS-303 (320.99) = 962.97; descuento 96.29 (no 96.297); final **866.68 MXN**.
- Los **ingresos de la sesion** suman el importe final (ya con descuento).

## 3. Organizacion de datos en memoria
`catalogo` = 10 registros de 44 bytes (440 bytes). Se recorre con ESI sumando `TAM_REGISTRO`.

| Offset | Campo | Tamano |
|---|---|---|
| 0 | Codigo `ABC-123` + 00h | 8 |
| 8 | Nombre (max 25 + 00h) | 26 |
| 34 | Precio en centavos | DWORD |
| 38 | Existencia (0-100) | DWORD |
| 42 | Estado (0 libre, 1 ocupado) | BYTE |
| 43 | Relleno | BYTE |

Otras variables: `ingresosSesion` (centavos), `cantidadProductos`, `cambiosSinGuardar`, buffers `bufEntrada` (64), `bufSalida` (15), `bufTexto` (1100), `catTmp` (440), `campo` (32) y temporales `tmp*` para no modificar el catalogo hasta confirmar la operacion.

## 4. Formato del archivo `InventarioMaquillaje.txt`
Texto plano (se abre con el Bloc de notas). Primera linea `GLM1`; despues una linea por producto separada por `;`:
```
GLM1
LAB-101;Labial Mate Rojo;189.50;25
RIM-202;Rimel Waterproof;145.00;40
```
Campos: codigo; nombre (1-25 caracteres, sin `;`); precio en pesos con 2 decimales; existencia. Cada linea termina en CR LF.
**Validacion al cargar (antes de reemplazar el catalogo):** se lee a `bufTexto` (maximo 1023 bytes; vacio o mas grande se rechaza) y se pone 00h tras los bytes leidos. `ParsearTexto` lee campo por campo (`LeerCampo`) hacia un catalogo temporal `catTmp`: firma `GLM1`, codigo `ABC-123`, nombre de 1 a 25, precio con `ParsePrecio`, existencia 0..100 con `ParseEntero`, maximo 10 lineas. Luego `ValidarCatalogo` revisa rangos y codigos repetidos. Solo si todo es correcto se copia `catTmp` a `catalogo`. Si el archivo no existe o falla algo, se avisa y el catalogo queda vacio.
**Al guardar:** se arma el texto en `bufTexto` (con `EscribirPrecio` y `EscribirNumero`), se escribe con `WriteToFile` y se comprueba que EAX sea igual a los bytes solicitados.

## 5. Decisiones del codigo
- Todo se captura con `ReadString` (EDX = buffer, ECX = maximo, EAX = longitud) y se convierte con rutinas propias.
- Precio: acumula digitos (x10 + digito), cuenta decimales (1 o 2), rechaza vacio, simbolos, comas, `12.`, tercer decimal y fuera de 0.01-9999.99; si hay 0 o 1 decimal escala a centavos.
- Una operacion rechazada vuelve al menu sin tocar el catalogo (todo se calcula en temporales y se confirma al final).
- Desbordamiento: `MUL` activa CF si EDX<>0 y `ADD` activa CF al pasar de 32 bits; maximos: importe 99,999,900; valor del inventario 999,999,000 (< 4,294,967,295).
- Solo se usaron instrucciones vistas en clase; los copiados y comparaciones de cadenas se hacen con ciclos byte a byte.

## 6. Fuentes 
- Irvine, K. R. *Assembly Language for x86 Processors* (7a ed.): capitulo de aritmetica entera (MUL, DIV), de procedimientos/pila y de E/S de archivos (CreateOutputFile, OpenInputFile, WriteToFile, ReadFromFile, CloseFile).
- Apuntes y practicas de la Unidad 2 (repositorio del curso).
