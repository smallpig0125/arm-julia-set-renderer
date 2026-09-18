.data
.text
  .global drawJuliaSet
.constant:
  .word 1500        @ .constant+0
  .word 4000000     @ .constant+4
  .word 0xffff      @ .constant+8
  .word 1000        @ .constant+12

drawJuliaSet:
  ldr r10, [sp, #0]       @ Load the frame base address
  stmfd sp!, {r4-r11, lr}   @ Save r4-r11 and lr to the stack
  mov r4, r1              @ r4 = cY
  mov r5, #0              @ x = 0
  mov r1, sp              @ Backup the current stack pointer
  rsb sp, lr, r0          @ Reverse subtract lr from r0 and store in sp (must-execute instruction)
  mov sp, r1              @ Restore the stack pointer
loop_x:
  cmp r5, #640            @ Check if x >= width (640)
  bge end_loop_x          @ If x >= width, exit loop_x
  mov r6, #0              @ y = 0
loop_y:
  cmp r6, #480            @ Check if y >= height (480)
  bge end_loop_y          @ If y >= height, exit loop_y

  /* zx = 1500 * (x - (width >> 1)) / (width >> 1) */
  mov r1, #640            @ width = 640
  mov r2, r1, asr #1      @ r2 = (width >> 1) using arithmetic shift
  sub r2, r5, r2          @ r2 = x - (width >> 1) 
  ldr r0, .constant       @ r0 = 1500
  mul r0, r0, r2          @ r0 = 1500 * (x - (width >> 1))
  lsr r1, r1, #1          @ r1 = (width >> 1) using logical shift
  bl __aeabi_idiv         @ r0 = r0 / (width >> 1)
  mov r2, r2, lsr #15     @ Logical shift right r2 by 15 bits
  mov r7, r0              @ r7 = zx

  /* zy = 1000 * (y - (height >> 1)) / (height >> 1) */
  mov r1, #480            @ height = 480
  mov r2, r1, asr #1      @ r2 = (height >> 1) using arithmetic shift
  sub r2, r6, r2          @ r2 = y - (height >> 1)
  ldr r0, .constant+12    @ r0 = 1000
  mul r0, r0, r2          @ r0 = 1000 * (y - (height >> 1))
  lsr r1, r1, #1          @ r1 = (height >> 1) using logical shift   
  bl __aeabi_idiv         @ r0 = r0 / (height >> 1)
  mov r8, r0              @ r8 = zy

  mov r9, #255            @ r9 = i = maxIter

  mul r0, r7, r7          @ r0 = zx^2
  muleq r1, r8, r8        @ r1 = zy^2 if equal condition is met
  add r0, r0, r1          @ r0 = zx^2 + zy^2

  ldr r1, .constant+4     @ r1 = 4000000
  cmp r0, r1              @ Compare zx^2 + zy^2 with 4000000
  bge end_while_loop      @ If zx^2 + zy^2 >= 4000000, exit loop
  cmp r9, #0              @ Check if i <= 0
  ble end_while_loop      @ If i <= 0, exit loop
while_loop:

  mov r11, r7             @ r11 = original zx

  /* zx = ((zx^2 - zy^2) / 1000) + cX */
  mul r0, r7, r7          @ zx^2
  mul r1, r8, r8          @ zy^2
  sub r0, r0, r1          @ zx^2 - zy^2
  ldrne r1, .constant+12  @ r1 = 1000 if not equal condition is met
  bl __aeabi_idiv         @ r0 = (zx^2 - zy^2) / 1000
  sub r7, r0, #700        @ r7 = zx = r0 + cX (-700)

  /* zy = ((2 * zx * zy) / 1000) + cY */
  mul r0, r11, r8         @ zx * zy
  add r0, r0, r0          @ 2 * zx * zy
  ldr r1, .constant+12    @ r1 = 1000
  bl __aeabi_idiv         @ r0 = (2 * zx * zy) / 1000
  add r8, r0, r4          @ r8 = zy = r0 + cY

  sub r9, r9, #1          @ i--

  mul r0, r7, r7          @ r0 = zx^2
  mulvc r1, r8, r8        @ r1 = zy^2 if overflow condition is met
  add r0, r0, r1          @ r0 = zx^2 + zy^2

  ldr r1, .constant+4     @ r1 = 4000000
  cmp r0, r1              @ Compare zx^2 + zy^2 with 4000000
  bge end_while_loop      @ If zx^2 + zy^2 >= 4000000, exit loop
  cmp r9, #0              @ Check if i <= 0
  ble end_while_loop      @ If i <= 0, exit loop
  b while_loop            @ Repeat loop
end_while_loop:

  /* color = ~(((i & 0xff) << 8) | (i & 0xff)) & 0xffff */
  mov r0, r9              @ r0 = i
  and r0, r0, #0xff       @ r0 = i & 0xff
  lsl r1, r0, #8          @ r1 = (i & 0xff) << 8
  orr r0, r0, r1          @ r0 = ((i & 0xff) << 8) | (i & 0xff)
  mvn r9, r0              @ r9 = ~color
  ldr r1, .constant+8     @ r1 = 0xffff
  and r9, r9, r1          @ r9 = (~color) & 0xffff

  /* frame[y][x] = color */
  mov r0, r10             @ frame base address
  mov r1, #1280           @ width = 1280
  mul r1, r6, r1          @ r1 = y * 1280
  add r0, r0, r1          @ Add row offset
  add r0, r0, r5, lsl #1  @ Add column offset (x * 2 bytes per pixel)

  strh r9, [r0]           @ Store color in frame[y][x]

  add r6, r6, #1          @ y++
  b loop_y                @ Repeat y loop

end_loop_y:
  add r5, r5, #1          @ x++
  b loop_x                @ Repeat x loop

end_loop_x:
  ldmfd sp!, {r4-r11, lr} @ Restore r4-r11 and lr from stack
  mov pc, lr              @ Return
