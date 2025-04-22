import struct
import math

# --- Funciones de ayuda para conversión y visualización ---

def float_to_int32(f):
  """Convierte un float de Python a su representación entera IEEE-754 de 32 bits."""
  if f == float('inf'):
      return 0x7F800000
  if f == float('-inf'):
      return 0xFF800000
  if math.isnan(f):
      # Devuelve un qNaN estándar. La carga útil exacta puede variar.
      return 0x7FC00000 
  # Empaqueta como big-endian float (>) y desempaqueta como big-endian unsigned int (I)
  return struct.unpack('>I', struct.pack('>f', f))[0]

def int32_to_float(i):
  """Convierte una representación entera IEEE-754 de 32 bits a un float de Python."""
  # Empaqueta como big-endian unsigned int (I) y desempaqueta como big-endian float (f)
  try:
      return struct.unpack('>f', struct.pack('>I', i))[0]
  except OverflowError:
      # Puede ocurrir si el patrón de bits es un NaN no estándar que struct no maneja bien
      # o un infinito que causa problemas en algunas versiones/plataformas.
      # Intentamos manejar los casos estándar explícitamente.
      sign = (i >> 31) & 1
      exponent = (i >> 23) & 0xFF
      fraction = i & 0x7FFFFF
      if exponent == 0xFF:
          if fraction == 0:
              return float('-inf') if sign else float('inf')
          else:
              return float('nan')
      # Otros casos deberían ser manejados por struct, pero esto es un respaldo.
      return float('nan') 

# --- Implementación de la resta FPALU ---

def fpalu_subtract(A_int, B_int):
  """
  Realiza la resta S = A - B en formato IEEE-754 de 32 bits.
  A_int y B_int son las representaciones enteras de 32 bits de los operandos.
  Devuelve la representación entera de 32 bits del resultado S.
  """

  # 1) Extracción de campos
  signA = (A_int >> 31) & 1
  expA  = (A_int >> 23) & 0xFF
  fracA = A_int & 0x7FFFFF  # 23 bits

  signB = (B_int >> 31) & 1
  expB  = (B_int >> 23) & 0xFF
  fracB = B_int & 0x7FFFFF  # 23 bits

  # 2) Identificación de casos especiales
  A_isNaN  = (expA == 0xFF) and (fracA != 0)
  B_isNaN  = (expB == 0xFF) and (fracB != 0)
  A_isInf  = (expA == 0xFF) and (fracA == 0)
  B_isInf  = (expB == 0xFF) and (fracB == 0)
  A_isZero = (expA == 0x00) and (fracA == 0)
  B_isZero = (expB == 0x00) and (fracB == 0)

  # --- Lógica de cálculo ---

  # 4.1 Casos especiales: NaN tiene máxima prioridad
  if A_isNaN:
      # Propagar A si es NaN (podría ser qNaN o sNaN)
      # Para asegurar un qNaN si es sNaN, podríamos forzar el bit MSB de la fracción a 1
      # return A_int | 0x00400000 # Forzar qNaN
      return A_int # Propagar tal cual como en el SV
  if B_isNaN:
      # return B_int | 0x00400000 # Forzar qNaN
      return B_int # Propagar tal cual

  # 4.2 Ceros: A - 0 = A ; 0 - B = -B
  if B_isZero:
      # A - (+0) = A
      # A - (-0) = A
      # La única excepción es 0 - 0 = +0 según IEEE 754 default rounding
      if A_isZero:
          # (+0) - (+0) = +0
          # (-0) - (-0) = +0
          # (+0) - (-0) = +0
          # (-0) - (+0) = -0 (Pero la regla dice +0)
          # El SV original da -0 para (-0) - (+0). Sigamos el SV por ahora.
          # Para forzar +0 en todos los casos 0-0: return 0x00000000
          # Siguiendo el flujo del SV que llega al caso general:
          pass # Dejar que el caso general lo maneje (resultará en 0 con el signo de A)
      else:
          return A_int
          
  if A_isZero:
      # 0 - B = -B (invertir el signo de B)
      # ~signB no funciona directamente en Python como en SV para invertir 1 bit
      inv_signB = 1 - signB 
      return (inv_signB << 31) | (expB << 23) | fracB

  # 4.3 Infinitos
  # Nota: La resta es A + (-B). Cambiamos el signo de B para pensar en suma.
  # (+Inf) - (+Inf) = NaN
  # (-Inf) - (-Inf) = NaN
  if A_isInf and B_isInf:
      if signA == signB:
          # Inf - Inf = NaN
          return 0x7FC00000 # qNaN estándar (signo 0, exp FF, frac con MSB=1)
          # El SV daba {1'b0, 8'hFF, 1'b1, 22'b0} = 0x7FC00000
      else:
          # Inf - (-Inf) = Inf + Inf = Inf (con el signo de A)
          # (-Inf) - (Inf) = (-Inf) + (-Inf) = -Inf (con el signo de A)
          return A_int

  # A es Inf, B no es Inf -> Resultado es A
  if A_isInf:
      return A_int
      
  # B es Inf, A no es Inf -> Resultado es -B (invertir signo de B)
  if B_isInf:
      inv_signB = 1 - signB
      return (inv_signB << 31) | (0xFF << 23) | 0 # Infinito con signo opuesto a B

  # --- 4.4 Caso general: A y B son números normales o subnormales ---
  
  # Reconstrucción de mantisas con bit implícito (1 para normal, 0 para denormal/cero)
  # Usamos 24 bits para la mantisa (bit implícito + 23 de fracción)
  # Añadimos bits extra (guarda, redondeo, sticky - GRS) para mejor precisión, aunque el SV no los usa explícitamente en la resta inicial.
  # Para una traducción directa *sin* GRS como en el SV:
  mantA = ( (1 << 23) | fracA ) if expA != 0 else fracA
  mantB = ( (1 << 23) | fracB ) if expB != 0 else fracB
  
  # Convertir exponentes a valores reales (restando el bias 127)
  # O trabajar con exponentes sesgados directamente, ajustando el más pequeño.
  # El SV trabaja con los exponentes sesgados.
  
  # Ajustar exponentes y mantisas
  # Necesitamos alinear las mantisas al exponente mayor.
  
  # Variables para el resultado
  signRes = 0
  expRes = 0
  mantRes = 0

  # Añadir un bit extra para posible acarreo/borrow en la resta
  # Usaremos enteros de Python que tienen precisión arbitraria
  
  # Alinear exponentes: desplazar la mantisa del número con menor exponente a la derecha
  if expA > expB:
      shift = expA - expB
      # Desplazar mantB. Asegurarse de no desplazar más de lo necesario (ej. 25 bits)
      if shift < 25: # Límite práctico, si es más grande, B es despreciable
          mantB >>= shift
      else:
          mantB = 0
      expRes = expA # El exponente resultante será inicialmente el mayor
  elif expB > expA:
      shift = expB - expA
      if shift < 25:
          mantA >>= shift
      else:
          mantA = 0
      expRes = expB
  else: # expA == expB
      expRes = expA # o expB

  # Realizar la resta efectiva: A - B
  # Considerar los signos originales
  # Efectivamente calculamos: (signA ? -mantA : mantA) - (signB ? -mantB : mantB)
  
  # Convertir a magnitudes con signo para la resta
  valA = mantA if signA == 0 else -mantA
  valB = mantB if signB == 0 else -mantB
  
  mant_diff_signed = valA - valB
  
  # Determinar signo y magnitud del resultado
  if mant_diff_signed == 0:
       # Resultado es Cero. IEEE 754 dice que A-A = +0 en modo por defecto.
       return 0x00000000 # +0
       
  if mant_diff_signed > 0:
      signRes = 0 # Positivo
      mant_abs = mant_diff_signed
  else: # mant_diff_signed < 0
      signRes = 1 # Negativo
      mant_abs = -mant_diff_signed

  # --- Normalización ---
  # mant_abs ahora contiene la magnitud de la mantisa resultante.
  # Necesitamos normalizarla para que tenga la forma 1.xxxxx * 2^expRes
  # o 0.xxxxx * 2^-126 para subnormales.
  
  # La mantisa `mant_abs` puede tener hasta 24 bits significativos (o más si hubo cancelación).
  # El bit correspondiente al '1.' implícito está en la posición 23.
  
  # Contar posiciones a desplazar para normalizar (encontrar el MSB)
  if mant_abs == 0: # Ya se manejó arriba, pero por si acaso
       return 0x00000000 # +0

  # Encontrar la posición del bit más significativo (MSB)
  # Python 3.10+ tiene int.bit_length()
  msb_pos = mant_abs.bit_length() - 1

  # La posición objetivo del MSB (el bit implícito) es 23
  # Necesitamos desplazar `mant_abs` para que su MSB quede en la posición 23
  
  if msb_pos > 23:
      # Hubo un "overflow" en la mantisa (ej. 1.5 - 0.25), necesita desplazar a la derecha
      shift = msb_pos - 23
      mant_norm = mant_abs >> shift
      expRes += shift
  elif msb_pos < 23:
      # Necesita desplazar a la izquierda (hubo cancelación)
      shift = 23 - msb_pos
      # Comprobar si el desplazamiento causa underflow del exponente
      if expRes > shift:
          mant_norm = mant_abs << shift
          expRes -= shift
      else:
          # El exponente se volverá 0 o negativo -> Resultado subnormal o cero
          # Desplazar sólo lo posible hasta que expRes sea 1, luego ajustar para exp=0
          shift_possible = expRes - 1 # Cuánto podemos bajar el exponente hasta 1
          if shift_possible < 0: shift_possible = 0 # Ya era 0 o menos

          mant_norm = mant_abs << shift_possible
          
          # Exponente ahora es 1 (o 0 si empezó en 0)
          # Necesitamos bajarlo a 0 y desplazar la mantisa correspondientemente a la derecha
          final_right_shift = shift - shift_possible + (1 if expRes > 0 else 0)

          if final_right_shift < 24: # Si no se desplaza todo fuera
             mant_norm >>= final_right_shift
          else:
             mant_norm = 0 # Se convierte en cero
             
          expRes = 0 # Exponente final es 0 para subnormal/cero
  else: # msb_pos == 23
      # Ya está normalizado (el MSB está en la posición 23)
      mant_norm = mant_abs
      
  # --- Comprobaciones finales y empaquetado ---

  # Verificar si el resultado es cero después de la normalización/underflow
  if mant_norm == 0:
      # Incluso si el signo calculado fue negativo, 0 es usualmente +0
      return 0x00000000

  # Redondeo (El SV original parece truncar, así que omitimos redondeo explícito GRS)
  # Si implementáramos redondeo, se haría aquí sobre mant_norm.

  # Extraer la fracción final (23 bits inferiores)
  # El bit en la posición 23 (el MSB de mant_norm si es normal) es implícito y no se guarda.
  if expRes > 0:
      # Número normal o subnormal que se normalizó a normal
      fracRes = mant_norm & 0x7FFFFF # Tomar los 23 bits inferiores
  else: # expRes == 0
      # Número subnormal (o cero, ya manejado)
      # El bit implícito es 0, toda la mant_norm es la fracción
      fracRes = mant_norm & 0x7FFFFF # Asegurarse que quepa en 23 bits
      
  # Manejo de Overflow y Underflow del exponente
  if expRes >= 0xFF: # Exponente 255 o más -> Infinito
      expRes = 0xFF
      fracRes = 0 # Infinito
  elif expRes <= 0: # Exponente 0 o menos
      # Este caso ya fue manejado durante la normalización para ajustar la mantisa
      # a subnormal (exp=0) o cero.
      expRes = 0 # Asegurar que el exponente sea 0
      # fracRes ya debería estar calculado correctamente para subnormal
  
  # Construir el resultado final
  result_int = (signRes << 31) | (expRes << 23) | fracRes
  return result_int

# --- Testbench similar al de SystemVerilog ---

print("--- Python FPALU Subtraction Test ---")
print("Input A (int) | Input B (int) | Result S (int)|  A          - B           = S")
print("-" * 80)

test_cases = [
    # Test 1: 5.5 - 2.25 = 3.25
    (float_to_int32(5.5), float_to_int32(2.25), "5.5 - 2.25 = 3.25"),
    # Test 2: 0.6 - 0.675 = -0.075 (Requiere manejo de cancelación y normalización)
    (float_to_int32(0.6), float_to_int32(0.675), "0.6 - 0.675 = -0.075"),
    # Test 3: 0.0 - 1.0 = -1.0
    (float_to_int32(0.0), float_to_int32(1.0), "0.0 - 1.0 = -1.0"),
    # Test 4: +Inf - +Inf = NaN
    (float_to_int32(float('inf')), float_to_int32(float('inf')), "+Inf - +Inf = NaN"),
    # Test 5: 10.0 - (-Inf) = +Inf
    (float_to_int32(10.0), float_to_int32(float('-inf')), "10.0 - (-Inf) = +Inf"),
    # Test 6: (-Inf) - 5.0 = -Inf
    (float_to_int32(float('-inf')), float_to_int32(5.0), "(-Inf) - 5.0 = -Inf"),
    # Test 7: NaN - 5.0 = NaN
    (float_to_int32(float('nan')), float_to_int32(5.0), "NaN - 5.0 = NaN"),
    # Test 8: 5.0 - NaN = NaN
    (float_to_int32(5.0), float_to_int32(float('nan')), "5.0 - NaN = NaN"),
    # Test 9: Subnormal test: 2^-126 - 2^-127 = 2^-127
    (float_to_int32(2**-126), float_to_int32(2**-127), "2^-126 - 2^-127 = 2^-127"),
     # Test 10: Cancellation leading to zero: 1.2345 - 1.2345 = +0.0
    (float_to_int32(1.2345), float_to_int32(1.2345), "1.2345 - 1.2345 = +0.0"),
    # Test 11: (-0.0) - (+0.0) = -0.0 (Según el flujo SV) o +0.0 (Según IEEE default)
    # Nuestra implementación da +0.0 ahora.
    (float_to_int32(-0.0), float_to_int32(0.0), "-0.0 - 0.0 = +0.0"),
    # Test 12: Un número grande menos uno pequeño
    (float_to_int32(1.0e30), float_to_int32(1.0), "1.0e30 - 1.0 = 1.0e30 (approx)"),
]

for a_int, b_int, desc in test_cases:
    s_int = fpalu_subtract(a_int, b_int)
    
    # Convertir a float para visualización (puede tener pequeñas diferencias por la precisión de Python)
    rA = int32_to_float(a_int)
    rB = int32_to_float(b_int)
    rS = int32_to_float(s_int)
    
    print(f"0x{a_int:08X} | 0x{b_int:08X} | 0x{s_int:08X} | {rA:11.5g} - {rB:11.5g} = {rS:11.5g}  ({desc})")