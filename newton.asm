default rel
global newton

section .data
mask_bc:  db 0 0 0 0xFF
section .text
;; int newton(int n_particles, double size, double *position,
;;                   RDI     ,        XMM0,           RSI   ,
;;            double *velocity, double *force, double *potential)
;;                      RDX   ,          RSX ,            R8

newton:
  push r12
  push r13
  push r14
  push r15
  xor r9, r9
  mov [r8], r9
  mov rcx, rdi
  mul rcx, 3
  mov r10, rsx
  ;; toda esta vuelta es para dividir por 2
  mov r12, 1
  cvtss2sd ymm1, r12
  shufpd ymm1, [mask_bc]
  divpd ymm1, 2
  ;; -1/2
  mov r14, -1
  cvtss2sd ymm3, r14
  movdq ymm2, ymm1
  mulpd ymm2, ymm3

  ;;  broadcast de size
  shufpd ymm0, [mask_bc]
  mulpd ymm1, ymm0
  mulpd ymm2, ymm0
  .zero:
    mov [r10], r9
    add r10, 8
  loop .zero

  mov rcx, rdi
  .part_i:
    mov r11, rcx
    mov r12, rdi
    sub r12, rcx
    mul r12, 24                             ; 24 = 3 (DIM) * 8 (size)
    movdqu ymm15, [rsi + r12]               ; unaligned es lento
    .part_j:
      mov r12, rdi
      sub r12, r11
      mul r12, 24                           ; 24 = 3 (DIM) * 8 (size)
      movdqu ymm14, [rsi + r12]             ; unaligned es lento
      subpd ymm14, ymm15                    ; ymm14 es posición j - i
      movdq ymm13, ymm14
      cmppd ymm13, ymm1, 0xD                ; mayor o igual a size/2
      movdq ymm12, ymm14
      cmppd ymm12, ymm2, 0x1                ; menor a -size/2
      movdq ymm11, ymm13
      movdq ymm10, ymm12
      vandpd ymm12, ymm14                   ; (comparar con vpand)
      vandpd ymm13, ymm14                   ;
      vpand ymm9, ymm12, ymm13             ; todos los que modificamos
      not ymm9             ; todos los que no modificamos
      vpand ymm14, ymm9    ; ymm14 son LOS VALORES que no modificamos
      vsubpd ymm13, ymm0
      vandpd ymm11, ymm13
      vaddpd ymm12, ymm0
      vandpd ymm10, ymm12

      vaddpd ymm14, ymm10
      vaddpd ymm14, ymm12       ; esto para juntarlos porque sabemos que son 0 los cruzados
      vmulpd ymm14, ymm14
      vdppd ymm14, ymm14, 11100001b ;chequear este número
      dec r11
      jnz .part_j

    loop .part_i
