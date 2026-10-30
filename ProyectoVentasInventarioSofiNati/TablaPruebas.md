# Tabla de pruebas

Con `InventarioMaquillaje.txt` de prueba: LAB-101 $189.50 x25, RIM-202 $145.00 x40, BAS-303 $320.99 x12, SOM-404 $275.00 x2.
**Columna "Obtenido": llenala al ejecutar el programa** 
| # | Prueba | Entrada | Resultado esperado | Obtenido |

| 1 | Carga | Iniciar con el .txt | "Catalogo cargado"; Consultar muestra 4 productos | |
| 2 | Alta valida | `PER-505` / `Delineador Negro` / `99.90` / `10` | "Operacion realizada"; aparece con 99.90 MXN y 10 | |
| 3 | Alta duplicada | `LAB-101` | "ya existe un producto con ese codigo"; no cambia nada | |
| 4 | Codigo invalido | `lab-101`, `LAB101`, `LA1-123`, vacio | "codigo invalido" | |
| 5 | Nombre invalido | vacio o 26+ caracteres | "nombre debe tener de 1 a 25" | |
| 6 | Precio entero | `185` | Se guarda 185.00 MXN | |
| 7 | Precio con decimales | `185.50`, `12.05`, `12.5` | 185.50, 12.05, 12.50 MXN | |
| 8 | Precio invalido | `12.555`, `12.`, `.50`, `$12`, `1,200`, `abc`, vacio | "precio invalido o fuera de rango" | |
| 9 | Precio fuera de rango | `0`, `0.00`, `10000` | Rechazado | |
| 10 | Precio limite | `0.01` y `9999.99` | Aceptados | |
| 11 | Inventario lleno | Dar de alta hasta 10 y un 11o | "inventario esta lleno (Max 10)" | |
| 12 | Buscar existente | `RIM-202` | `RIM-202 \| Rimel Waterproof \| 145.00 MXN \| 40` | |
| 13 | Buscar inexistente | `ZZZ-999` | "codigo no encontrado" | |
| 14 | Entrada valida | `LAB-101`, cantidad `10` | Existencia 35 | |
| 15 | Entrada excesiva | `LAB-101`, cantidad `76` (25+76 > 100) | "no puede superar 100"; sigue en 25 | |
| 16 | Entrada invalida | cantidad `0`, `-5`, `abc`, `2.5`, vacio | "cantidad invalida"; existencia igual | |
| 17 | Venta sin descuento | `LAB-101`, `1` | Base 189.50, final 189.50; existencia -1; ingresos 189.50 | |
| 18 | Venta con descuento | `RIM-202`, `3` | Base 435.00, descuento 43.50, final 391.50; existencia 37 | |
| 19 | Descuento con fraccion | `BAS-303`, `3` | Base 962.97, descuento 96.29, final 866.68 | |
| 20 | Venta rechazada | `SOM-404`, `3` (hay 2) | "existencias insuficientes"; existencia 2; ingresos sin cambio | |
| 21 | Venta cantidad invalida | `0` o `abc` | "cantidad invalida" | |
| 22 | Resumen (recien cargado) | Opcion 6 | Unidades 79; valor 14939.38 MXN; ingresos 0.00 MXN | |
| 23 | Resumen tras ventas 17-19 | Opcion 6 | Ingresos 189.50 + 391.50 + 866.68 = 1447.68 MXN | |
| 24 | Salir con cambios | Opcion 8 tras una venta | Pregunta "Guardar antes de salir? (S/N)" | |
| 25 | Guardar y recargar | Opcion 7, salir, reabrir | Mismo catalogo; ingresos de sesion en 0.00 | |
| 26 | Archivo ausente | Borrar el .txt y ejecutar | "no existe archivo"; catalogo vacio, el menu funciona | |
| 27 | Archivo danado | Editar el .txt: firma distinta de `GLM1`, precio `12.555`, codigo repetido, falta un `;`, existencia `101` o mas de 10 lineas | "archivo danado o invalido"; catalogo vacio | |
| 27b | Nombre con `;` | Alta con nombre `Rubor;Rosa` | "nombre debe tener de 1 a 25 caracteres y no usar ';'" | |
| 28 | Opcion de menu invalida | `9`, `ab`, vacio | "opcion invalida" y vuelve al menu | |
