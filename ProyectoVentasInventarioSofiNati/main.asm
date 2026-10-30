; Materia: Lenguajes de Interfaz
; Alumna: Frida Sofia Vega Vazquez y Natalia Lopez Ibarra
; Horario: 8 a 9 am
; Docente: Dr. José Luis Medina Jiménez
; Proyecto: Sistema de Ventas e Inventario (Glamour Makeup Sinaloa)
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INCLUDE Irvine32.inc

TAM_REGISTRO EQU 44
MAX_PRODUCTOS EQU 10

.data 
    ; --- Archivo binario de respaldo para persistencia entre ejecuciones ---
    nomCatDat BYTE "catalogo.dat", 0

    ; --- Archivos de texto físicos (Basados estrictamente en Práctica 15) ---
    nomCatTxt BYTE "catalogo.txt", 0
    nomMovTxt BYTE "movimientos.txt", 0
    nomVenTxt BYTE "ventas.txt", 0
    
    archivoHandle DWORD ?                   ; Almacenar el identificador del archivo

    ; --- Inventario en memoria (440 bytes) ---
    ingresosSesion DWORD 0
    cantidadProductos DWORD 0
    catalogo BYTE 440 DUP(0)
    
    ; --- Buffers de texto para los 3 archivos ---
    bufCatTxt BYTE 2000 DUP(0)
    bufMovTxt BYTE 3000 DUP(0)
    bufVenTxt BYTE 3000 DUP(0)
    
    ; --- Mensajes de la Interfaz ---
    msgMenu         BYTE 0Ah, 0Dh, "--- GLAMOUR MAKEUP SINALOA ---", 0Ah, 0Dh
                    BYTE "1. Registrar Producto", 0Ah, 0Dh
                    BYTE "2. Consultar Inventario", 0Ah, 0Dh
                    BYTE "3. Recibir Mercancia", 0Ah, 0Dh
                    BYTE "4. Vender Producto", 0Ah, 0Dh
                    BYTE "5. Mostrar Resumen", 0Ah, 0Dh
                    BYTE "6. Salir", 0Ah, 0Dh
                    BYTE "Elige una opcion (1-6): ", 0
                    
    msgPedirCodigo  BYTE "Ingresa codigo (ABC-123): ", 0
    msgPedirNombre  BYTE "Nombre del cosmetico: ", 0
    msgPedirPrecio  BYTE "Precio en MXN (ej. 450.50): ", 0
    msgPedirCant    BYTE "Cantidad: ", 0
    
    msgErrorGen     BYTE "Error: Dato invalido o formato incorrecto.", 0Ah, 0Dh, 0
    msgExito        BYTE "Operacion realizada con exito.", 0Ah, 0Dh, 0
    msgLleno        BYTE "Error: Inventario lleno (Max 10).", 0Ah, 0Dh, 0
    msgNoEncontrado BYTE "Error: Codigo no encontrado.", 0Ah, 0Dh, 0
    msgDuplicado    BYTE "Error: Codigo duplicado. Ya existe en el catalogo.", 0Ah, 0Dh, 0
    msgMaxAlcanzado BYTE "Error: El producto ya tiene la existencia maxima (100 unidades).", 0Ah, 0Dh, 0
    msgExcedeMax    BYTE "Error: La cantidad ingresada supera el limite maximo permitida (Max 100).", 0Ah, 0Dh, 0
    msgSinStock     BYTE "Error: El producto no tiene existencias para vender.", 0Ah, 0Dh, 0
    msgNoSuficiente BYTE "Error: No hay suficiente existencia en inventario para esta venta.", 0Ah, 0Dh, 0
    msgDescuento    BYTE ">> AVISO: Descuento de mayoreo (10%) aplicado.", 0Ah, 0Dh, 0
    msgMXN          BYTE " MXN", 0
    msgSeparador    BYTE " | ", 0
    
    msgResumen      BYTE 0Ah, 0Dh, "--- RESUMEN DEL NEGOCIO ---", 0Ah, 0Dh, 0
    msgUnidades     BYTE "Unidades totales disponibles: ", 0
    msgTotalInv     BYTE "Valor total del inventario:   ", 0
    msgTotalIngr    BYTE "Ingresos totales de la sesion:", 0
    
    bufEntrada      BYTE 30 DUP(0)
    bufSalida       BYTE 30 DUP(0)
    
    tempCantidad    DWORD ?
    tempTotal       DWORD ?

    ; --- Formato de texto para los archivos .txt ---
    strEntradaTag   BYTE "[ENTRADA] Codigo: ", 0
    strSalidaTag    BYTE "[SALIDA]  Codigo: ", 0
    strVentaTag     BYTE "[VENTA]   Codigo: ", 0
    strCantTag      BYTE " | Cantidad actual: ", 0
    strImpTag       BYTE " | Importe: ", 0
    strCRLF         BYTE 0Dh, 0Ah, 0

.code
main PROC
    call CargarCatalogo                 ; <-- Cargar datos guardados previamente al iniciar

MenuLoop:
    mov edx, OFFSET msgMenu
    call WriteString
    mov edx, OFFSET bufEntrada
    mov ecx, SIZEOF bufEntrada
    call ReadString
    
    cmp eax, 1                  
    jne OpcionInvalida
    
    mov al, bufEntrada[0]
    cmp al, '1'
    je OpcionAlta
    cmp al, '2'
    je OpcionConsultar
    cmp al, '3'
    je OpcionRecibir
    cmp al, '4'
    je OpcionVender
    cmp al, '5'
    je OpcionResumen
    cmp al, '6'
    je FinPrograma
    
OpcionInvalida:
    mov edx, OFFSET msgErrorGen
    call WriteString
    jmp MenuLoop

OpcionAlta:
    call RegistrarProducto
    jmp MenuLoop
OpcionConsultar:
    call ConsultarInventario
    jmp MenuLoop
OpcionRecibir:
    call RecibirMercancia
    jmp MenuLoop
OpcionVender:
    call VenderProducto
    jmp MenuLoop
OpcionResumen:
    call MostrarResumen
    jmp MenuLoop

FinPrograma:
    exit
main ENDP

; =========================================================
; CARGAR Y GUARDAR PERSISTENCIA BINARIA (catalogo.dat)
; =========================================================
CargarCatalogo PROC
    push eax
    push ecx
    push edx
    push esi

    mov edx, OFFSET nomCatDat
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je FinCargar                         ; Si el archivo no existe (1ra vez), no carga nada

    mov archivoHandle, eax

    mov edx, OFFSET catalogo
    mov ecx, SIZEOF catalogo
    call ReadFromFile

    mov eax, archivoHandle
    call CloseFile

    ; Recalcular cantidad de productos activos en la memoria cargada
    mov cantidadProductos, 0
    mov esi, OFFSET catalogo
    mov ecx, MAX_PRODUCTOS
CicloContar:
    cmp BYTE PTR [esi+42], 1
    jne SigContar
    inc cantidadProductos
SigContar:
    add esi, TAM_REGISTRO
    loop CicloContar

FinCargar:
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
CargarCatalogo ENDP

GuardarRespaldoDat PROC
    push eax
    push ecx
    push edx

    mov edx, OFFSET nomCatDat
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je FinGuardarDat

    mov archivoHandle, eax
    mov edx, OFFSET catalogo
    mov ecx, SIZEOF catalogo
    call WriteToFile

    mov eax, archivoHandle
    call CloseFile

FinGuardarDat:
    pop edx
    pop ecx
    pop eax
    ret
GuardarRespaldoDat ENDP

; =========================================================
; SUBRUTINA DE BÚSQUEDA
; =========================================================
BuscarProducto PROC
    push ebx
    push ecx
    push edi

    mov esi, OFFSET catalogo
    mov ecx, MAX_PRODUCTOS

CicloBusq:
    cmp BYTE PTR [esi+42], 1            ; ¿El espacio está ocupado?
    jne SigBusq

    push ecx
    push esi                            ; Respaldar inicio del producto
    push edi
    mov edi, OFFSET bufEntrada
    mov ecx, 7                          ; Comparar formato ABC-123
    repe cmpsb
    pop edi
    pop esi                             ; Restaurar ESI al inicio del producto
    pop ecx
    je Encontrado                       ; Si coincide, se mantiene ESI

SigBusq:
    add esi, TAM_REGISTRO
    loop CicloBusq

    pop edi
    pop ecx
    pop ebx
    mov eax, 0                          ; Retorna 0 (No encontrado)
    ret

Encontrado:
    pop edi
    pop ecx
    pop ebx
    mov eax, 1                          ; Retorna 1 (Encontrado)
    ret
BuscarProducto ENDP

; =========================================================
; SUBRUTINAS DE ARCHIVOS (Basadas en Práctica 15)
; =========================================================
ObtenerLongitud PROC
    push esi
    push eax
    mov ecx, 0
CicloL:
    mov al, [esi]
    cmp al, 0
    je FinL
    inc ecx
    inc esi
    jmp CicloL
FinL:
    pop eax
    pop esi
    ret
ObtenerLongitud ENDP

EscribirCadenaEnArchivo PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi

    push edx                            ; Respaldar offset del nombre
    call ObtenerLongitud                ; Calcula longitud del texto en ECX
    pop edx                             ; Recuperar nombre

    cmp ecx, 0
    je FinEscribir

    push ecx                            ; Respaldar bytes a escribir

    ; 1. Crear archivo txt (Práctica 15)
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je ErrorCrear

    mov archivoHandle, eax

    ; 2. Escribir caracteres en archivo txt (Práctica 15)
    pop ecx                             ; Recuperar tamaño
    mov eax, archivoHandle
    mov edx, esi                        ; EDX = buffer de texto
    call WriteToFile

    ; 3. Cerrar archivo txt (Práctica 15)
    mov eax, archivoHandle
    call CloseFile
    jmp FinEscribir

ErrorCrear:
    pop ecx
FinEscribir:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
EscribirCadenaEnArchivo ENDP

GuardarArchivosSistema PROC
    push eax
    push edx
    push esi

    ; 0. Guardar respaldo binario para persistencia entre ejecuciones
    call GuardarRespaldoDat

    ; 1. Guardar catalogo.txt
    call ActualizarBufferCatalogo
    mov edx, OFFSET nomCatTxt
    mov esi, OFFSET bufCatTxt
    call EscribirCadenaEnArchivo

    ; 2. Guardar movimientos.txt
    mov edx, OFFSET nomMovTxt
    mov esi, OFFSET bufMovTxt
    call EscribirCadenaEnArchivo

    ; 3. Guardar ventas.txt
    mov edx, OFFSET nomVenTxt
    mov esi, OFFSET bufVenTxt
    call EscribirCadenaEnArchivo

    pop esi
    pop edx
    pop eax
    ret
GuardarArchivosSistema ENDP

; =========================================================
; MANEJO DE BUFFERS DE TEXTO
; =========================================================
ActualizarBufferCatalogo PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov edi, OFFSET bufCatTxt
    mov BYTE PTR [edi], 0

    mov esi, OFFSET catalogo
    mov ecx, MAX_PRODUCTOS

CicloCat:
    cmp BYTE PTR [esi+42], 1            
    jne SigCat

    ; Código
    push esi
    call AnexarCadena
    mov esi, OFFSET msgSeparador
    call AnexarCadena
    pop esi

    ; Nombre
    push esi
    add esi, 8
    call AnexarCadena
    mov esi, OFFSET msgSeparador
    call AnexarCadena
    pop esi

    ; Precio
    push esi
    mov eax, [esi+34]
    call FormatearMonedaCadena
    mov esi, OFFSET bufSalida
    call AnexarCadena
    mov esi, OFFSET msgSeparador
    call AnexarCadena
    pop esi

    ; Existencia
    push esi
    mov eax, [esi+38]
    push edi
    mov edi, OFFSET bufSalida
    call ConvertirNumATexto
    pop edi
    mov esi, OFFSET bufSalida
    call AnexarCadena
    mov esi, OFFSET strCRLF
    call AnexarCadena
    pop esi

SigCat:
    add esi, TAM_REGISTRO
    loop CicloCat

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
ActualizarBufferCatalogo ENDP

AnexarCadena PROC
    push eax
    push esi
CicloAnx:
    mov al, [esi]
    cmp al, 0
    je FinAnx
    mov [edi], al
    inc esi
    inc edi
    jmp CicloAnx
FinAnx:
    mov BYTE PTR [edi], 0
    pop esi
    pop eax
    ret
AnexarCadena ENDP

AnexarAMovimientos PROC
    push eax
    push esi
    push edi

    mov edi, OFFSET bufMovTxt
BuscFinMov:
    cmp BYTE PTR [edi], 0
    je CopiarAMov
    inc edi
    jmp BuscFinMov

CopiarAMov:
    mov al, [esi]
    cmp al, 0
    je FinAnxMov
    mov [edi], al
    inc esi
    inc edi
    jmp CopiarAMov

FinAnxMov:
    mov BYTE PTR [edi], 0
    pop edi
    pop esi
    pop eax
    ret
AnexarAMovimientos ENDP

AnexarAVentas PROC
    push eax
    push esi
    push edi

    mov edi, OFFSET bufVenTxt
BuscFinVen:
    cmp BYTE PTR [edi], 0
    je CopiarAVen
    inc edi
    jmp BuscFinVen

CopiarAVen:
    mov al, [esi]
    cmp al, 0
    je FinAnxVen
    mov [edi], al
    inc esi
    inc edi
    jmp CopiarAVen

FinAnxVen:
    mov BYTE PTR [edi], 0
    pop edi
    pop esi
    pop eax
    ret
AnexarAVentas ENDP

; =========================================================
; OPCIONES DEL MENÚ
; =========================================================
RegistrarProducto PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    cmp cantidadProductos, MAX_PRODUCTOS
    jae ErrorLleno

PedirCod:
    mov edx, OFFSET msgPedirCodigo
    call WriteString
    mov edx, OFFSET bufEntrada
    mov ecx, 10
    call ReadString
    cmp eax, 7                  
    jne ErrFormat

    mov esi, OFFSET bufEntrada
    cmp BYTE PTR [esi], 'A'
    jb ErrFormat
    cmp BYTE PTR [esi+2], 'Z'
    ja ErrFormat
    cmp BYTE PTR [esi+3], '-'
    jne ErrFormat
    cmp BYTE PTR [esi+4], '0'
    jb ErrFormat
    cmp BYTE PTR [esi+6], '9'
    ja ErrFormat

    ; --- COMPROBACIÓN DE DUPLICADOS ---
    call BuscarProducto
    cmp eax, 1
    je ErrDuplicado

    mov esi, OFFSET catalogo
    mov ecx, MAX_PRODUCTOS
BuscarLibre:
    cmp BYTE PTR [esi+42], 0
    je EspacioLibre
    add esi, TAM_REGISTRO
    loop BuscarLibre

EspacioLibre:
    mov edi, esi
    push esi
    mov esi, OFFSET bufEntrada
    mov ecx, 8
    rep movsb
    pop esi

PedirNom:
    mov edx, OFFSET msgPedirNombre
    call WriteString
    mov edx, OFFSET bufEntrada
    mov ecx, 26
    call ReadString
    cmp eax, 0
    je PedirNom

    lea edi, [esi+8]
    push esi
    mov esi, OFFSET bufEntrada
    mov ecx, 26
    rep movsb
    pop esi

PedirPre:
    mov edx, OFFSET msgPedirPrecio
    call WriteString
    mov edx, OFFSET bufEntrada
    mov ecx, 15
    call ReadString

    push esi
    mov esi, OFFSET bufEntrada
    call ParsePrecioCentavos
    pop esi
    jc ErrPrecio                        ; Si el precio falla, pide solo el precio de nuevo

    mov [esi+34], eax
    mov DWORD PTR [esi+38], 0
    mov BYTE PTR [esi+42], 1
    inc cantidadProductos

    call GuardarArchivosSistema

    mov edx, OFFSET msgExito
    call WriteString
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

ErrorLleno:
    mov edx, OFFSET msgLleno
    call WriteString
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

ErrDuplicado:
    mov edx, OFFSET msgDuplicado
    call WriteString
    jmp PedirCod

ErrPrecio:
    mov edx, OFFSET msgErrorGen
    call WriteString
    jmp PedirPre                        ; Reintenta únicamente la captura del precio

ErrFormat:
    mov edx, OFFSET msgErrorGen
    call WriteString
    jmp PedirCod
RegistrarProducto ENDP

ConsultarInventario PROC
    push eax
    push ecx
    push edx
    push esi

    mov ecx, MAX_PRODUCTOS
    mov esi, OFFSET catalogo
CicloCons:
    cmp BYTE PTR [esi+42], 1    
    jne SiguienteCons
    
    mov edx, esi
    call WriteString
    mov edx, OFFSET msgSeparador
    call WriteString
    lea edx, [esi+8]
    call WriteString
    mov edx, OFFSET msgSeparador
    call WriteString
    mov eax, [esi+34]
    call ImprimirMoneda
    mov edx, OFFSET msgSeparador
    call WriteString
    mov eax, [esi+38]
    mov edi, OFFSET bufSalida
    call ConvertirNumATexto
    mov edx, OFFSET bufSalida
    call WriteString
    call Crlf
SiguienteCons:
    add esi, TAM_REGISTRO
    loop CicloCons

    pop esi
    pop edx
    pop ecx
    pop eax
    ret
ConsultarInventario ENDP

RecibirMercancia PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov edx, OFFSET msgPedirCodigo
    call WriteString
    mov edx, OFFSET bufEntrada
    mov ecx, 10
    call ReadString

    call BuscarProducto
    cmp eax, 0
    je NoEncontrado

    ; --- PASO 1: VERIFICAR SI YA ESTÁ COMPLETAMENTE LLENO (100) ---
    cmp DWORD PTR [esi+38], 100
    jae YaLleno                          ; Si ya tiene 100, no pide nada y regresa al menú

PedirCantRec:
    mov edx, OFFSET msgPedirCant
    call WriteString
    mov edx, OFFSET bufEntrada
    mov ecx, 5
    call ReadString

    push esi
    mov esi, OFFSET bufEntrada
    call ConvertirTextoANum
    pop esi

    cmp eax, 0                          ; Validar que la cantidad ingresada sea > 0
    je ErrCantInvalida

    mov ebx, [esi+38]                   ; EBX = existencia actual (menor a 100)
    add ebx, eax                        ; EBX = total proyectado
    cmp ebx, 100
    ja ErrExcede100                     ; Si se pasa de 100, avisa y reintenta pedir cantidad

    mov [esi+38], ebx                   ; Guardar en catálogo

    ; Registrar en movimientos.txt
    push esi
    mov esi, OFFSET strEntradaTag
    call AnexarAMovimientos
    pop esi

    push esi
    call AnexarAMovimientos             ; Copia el código desde catálogo
    mov esi, OFFSET strCantTag
    call AnexarAMovimientos
    pop esi

    mov eax, [esi+38]
    push esi
    mov edi, OFFSET bufSalida
    call ConvertirNumATexto
    mov esi, OFFSET bufSalida
    call AnexarAMovimientos
    mov esi, OFFSET strCRLF
    call AnexarAMovimientos
    pop esi

    call GuardarArchivosSistema

    mov edx, OFFSET msgExito
    call WriteString
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

YaLleno:
    mov edx, OFFSET msgMaxAlcanzado
    call WriteString
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret                                 ; Sale al menú directamente porque el producto está lleno

NoEncontrado:
    mov edx, OFFSET msgNoEncontrado
    call WriteString
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

ErrCantInvalida:
    mov edx, OFFSET msgErrorGen
    call WriteString
    jmp PedirCantRec                    ; Vuelve a pedir la cantidad (ya que sí hay espacio disponible)

ErrExcede100:
    mov edx, OFFSET msgExcedeMax
    call WriteString
    jmp PedirCantRec                    ; Vuelve a pedir la cantidad (permite corregir la cantidad ingresada)
RecibirMercancia ENDP

VenderProducto PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov edx, OFFSET msgPedirCodigo
    call WriteString
    mov edx, OFFSET bufEntrada
    mov ecx, 10
    call ReadString

    call BuscarProducto
    cmp eax, 0
    je NoEncontrado

    ; --- PASO 1: VERIFICAR SI TIENE EXISTENCIAS PARA VENDER ---
    cmp DWORD PTR [esi+38], 0
    je SinStock                         ; Si no tiene nada, regresa al menú directamente

PedirCantVen:
    mov edx, OFFSET msgPedirCant
    call WriteString
    mov edx, OFFSET bufEntrada
    mov ecx, 5
    call ReadString

    push esi
    mov esi, OFFSET bufEntrada
    call ConvertirTextoANum
    pop esi

    mov tempCantidad, eax
    cmp eax, 0                          ; Validar que la cantidad a vender sea > 0
    je ErrCantVen

    cmp eax, [esi+38]
    ja ErrNoSuficiente                  ; Si pide más de lo disponible, reintenta pedir cantidad

    mov eax, [esi+34]
    mov ebx, tempCantidad
    mul ebx

    ; Regla de Negocio: Descuento de mayoreo (10% si >= 3 unidades)
    cmp tempCantidad, 3
    jb SinDescuento

    mov edx, OFFSET msgDescuento
    call WriteString
    mov ebx, 90
    mul ebx                     
    mov ebx, 100
    mov edx, 0
    div ebx

SinDescuento:
    mov tempTotal, eax
    add ingresosSesion, eax
    mov ebx, tempCantidad
    sub [esi+38], ebx                   ; Restar existencia en catálogo

    ; 1. Registrar salida en movimientos.txt
    push esi
    mov esi, OFFSET strSalidaTag
    call AnexarAMovimientos
    pop esi

    push esi
    call AnexarAMovimientos             ; Copia el código
    mov esi, OFFSET strCantTag
    call AnexarAMovimientos
    pop esi

    mov eax, [esi+38]
    push esi
    mov edi, OFFSET bufSalida
    call ConvertirNumATexto
    mov esi, OFFSET bufSalida
    call AnexarAMovimientos
    mov esi, OFFSET strCRLF
    call AnexarAMovimientos
    pop esi

    ; 2. Registrar venta en ventas.txt
    push esi
    mov esi, OFFSET strVentaTag
    call AnexarAVentas
    pop esi

    push esi
    call AnexarAVentas                  ; Copia el código
    mov esi, OFFSET strImpTag
    call AnexarAVentas
    pop esi

    mov eax, tempTotal
    push esi
    call FormatearMonedaCadena
    mov esi, OFFSET bufSalida
    call AnexarAVentas
    mov esi, OFFSET strCRLF
    call AnexarAVentas
    pop esi

    call GuardarArchivosSistema

    mov edx, OFFSET msgExito
    call WriteString
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

SinStock:
    mov edx, OFFSET msgSinStock
    call WriteString
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret                                 ; Regresa al menú directamente porque no hay stock

ErrCantVen:
    mov edx, OFFSET msgErrorGen
    call WriteString
    jmp PedirCantVen                    ; Reintenta pedir la cantidad

ErrNoSuficiente:
    mov edx, OFFSET msgNoSuficiente
    call WriteString
    jmp PedirCantVen                    ; Reintenta pedir la cantidad

NoEncontrado:
    mov edx, OFFSET msgNoEncontrado
    call WriteString
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
VenderProducto ENDP

MostrarResumen PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov tempTotal, 0
    mov tempCantidad, 0
    
    mov esi, OFFSET catalogo
    mov ecx, MAX_PRODUCTOS
CicloRes:
    cmp BYTE PTR [esi+42], 1
    jne SigRes
    
    mov eax, [esi+38]           
    add tempCantidad, eax
    mov ebx, [esi+34]           
    mul ebx                     
    add tempTotal, eax
SigRes:
    add esi, TAM_REGISTRO
    loop CicloRes

    mov edx, OFFSET msgResumen
    call WriteString
    
    mov edx, OFFSET msgUnidades
    call WriteString
    mov eax, tempCantidad
    mov edi, OFFSET bufSalida
    call ConvertirNumATexto
    mov edx, OFFSET bufSalida
    call WriteString
    call Crlf

    mov edx, OFFSET msgTotalInv
    call WriteString
    mov eax, tempTotal
    call ImprimirMoneda
    call Crlf

    mov edx, OFFSET msgTotalIngr
    call WriteString
    mov eax, ingresosSesion
    call ImprimirMoneda
    call Crlf

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
MostrarResumen ENDP

; =========================================================
; RUTINAS AUXILIARES Y CONVERSIONES
; =========================================================
ConvertirTextoANum PROC
    push ebx
    push ecx
    push edx
    push esi

    mov eax, 0
    mov ebx, 10

CicloTex:
    mov cl, [esi]
    cmp cl, 0
    je FinTex
    sub cl, '0'
    movzx edx, cl
    push edx
    mul ebx
    pop edx
    add eax, edx
    inc esi
    jmp CicloTex

FinTex:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
ConvertirTextoANum ENDP

ParsePrecioCentavos PROC
    push ebx
    push ecx
    push edx
    push esi

    mov eax, 0
    mov ebx, 10
    mov ecx, 0
    mov edx, 0

CicloParse:
    mov cl, [esi]
    cmp cl, 0
    je FinParse
    cmp cl, '.'
    jne NoPunto

    cmp edx, 1
    je ErrParse
    mov edx, 1
    jmp SigChar

NoPunto:
    cmp cl, '0'
    jb ErrParse
    cmp cl, '9'
    ja ErrParse

    push edx
    sub cl, '0'
    movzx edx, cl
    push edx
    mul ebx
    pop edx
    add eax, edx
    pop edx

    cmp edx, 1
    jne SigChar
    inc ch

SigChar:
    inc esi
    jmp CicloParse

FinParse:
    cmp ch, 0
    je Mult100
    cmp ch, 1
    je Mult10
    cmp ch, 2
    je OkParse
    jmp ErrParse

Mult100:
    mov ebx, 100
    mul ebx
    jmp OkParse

Mult10:
    mov ebx, 10
    mul ebx

OkParse:
    ; --- VALIDACIÓN DE RANGO $0.01 a $9999.99 MXN (1 a 999,999 centavos) ---
    cmp eax, 1
    jb ErrParse                     ; Rechaza $0.00
    cmp eax, 999999
    ja ErrParse                     ; Rechaza precios mayores a $9999.99 MXN

    pop esi
    pop edx
    pop ecx
    pop ebx
    clc                             ; Formato y rango válidos
    ret

ErrParse:
    pop esi
    pop edx
    pop ecx
    pop ebx
    stc                             ; Enciende Carry Flag (Error)
    ret
ParsePrecioCentavos ENDP

ConvertirNumATexto PROC
    push eax
    push ebx
    push ecx
    push edx
    push edi

    mov ecx, 0
    mov ebx, 10
CicloDividir:
    mov edx, 0
    div ebx
    add dl, '0'
    push edx
    inc ecx
    cmp eax, 0
    jne CicloDividir
CicloSacar:
    pop edx
    mov [edi], dl
    inc edi
    loop CicloSacar
    mov BYTE PTR [edi], 0

    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
ConvertirNumATexto ENDP

FormatearMonedaCadena PROC
    push eax
    push ebx
    push edx
    push edi

    mov ebx, 100
    mov edx, 0
    div ebx

    mov edi, OFFSET bufSalida
    call ConvertirNumATexto

    mov edi, OFFSET bufSalida
BuscFin:
    cmp BYTE PTR [edi], 0
    je AgregDec
    inc edi
    jmp BuscFin

AgregDec:
    mov BYTE PTR [edi], '.'
    inc edi

    cmp edx, 10
    jae CentavosNormales
    mov BYTE PTR [edi], '0'
    inc edi

CentavosNormales:
    mov eax, edx
    call ConvertirNumATexto

    mov edi, OFFSET bufSalida
BuscFin2:
    cmp BYTE PTR [edi], 0
    je AgregMXN
    inc edi
    jmp BuscFin2

AgregMXN:
    mov BYTE PTR [edi], ' '
    mov BYTE PTR [edi+1], 'M'
    mov BYTE PTR [edi+2], 'X'
    mov BYTE PTR [edi+3], 'N'
    mov BYTE PTR [edi+4], 0

    pop edi
    pop edx
    pop ebx
    pop eax
    ret
FormatearMonedaCadena ENDP

ImprimirMoneda PROC
    push eax
    push edx
    call FormatearMonedaCadena
    mov edx, OFFSET bufSalida
    call WriteString
    pop edx
    pop eax
    ret
ImprimirMoneda ENDP

END main
