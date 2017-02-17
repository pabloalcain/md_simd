default rel
global minimum_images

section .data
mask_bc:  db 0, 0, 0, 0xFF
mask_ones:   dq 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF 

section .text


;; void minimum_images(double size, const double *position
;;                           XMM0=    ,    RDI  
;;                     , int i, int j, double *dr) {
;;                        RSI  ,   RDX ,   RCX
%define size        ymm0
%define position_p  rdi
%define i           rsi
%define j           rdx
%define dr_p        rcx

minimum_images:
  
  ;; toda esta vuelta es para dividir por 2
  mov r8, 2
  cvtsi2sd xmm2, r8
  vperm2f128 ymm1, ymm0, ymm0, 00000000b
  vshufpd ymm1, ymm1, ymm1, 00000000b ; esto es un broadcast
  vmovdqa ymm0, ymm1
  vperm2f128 ymm2, ymm2, ymm2, 00000000b
  vshufpd ymm2, ymm2, ymm2, 00000000b ; esto es un broadcast
  vdivpd ymm1, ymm1, ymm2 ; ymm1 es size/2 en todos lados

  
  ;; -1/2
  mov r8, -1
  cvtsi2sd xmm3, r8
  vperm2f128 ymm3, ymm3, ymm3, 00000000b
  vshufpd ymm3, ymm3, ymm3, 00000000b ; esto es un broadcast
  vmulpd ymm2, ymm1, ymm3 ; ymm2 es -size/2 en todos lados

  mov r8, j
  mov rax, 24
  mul i                                   ; 24 = 3 (DIM) * 8 (size)
  vmovdqu ymm14, [position_p + rax]       ; unaligned es lento

  mov rax, 24
  mul r8                                   ; 24 = 3 (DIM) * 8 (size)
  vmovdqu ymm15, [position_p + rax]       ; unaligned es lento
  
  vsubpd ymm14, ymm15                    ; ymm14 es posición j - i

;; hasta acá: ymm14 es j - i

  
  vmovdqa ymm11, ymm14
  vcmppd ymm11, ymm1, 0xE                ; ymm11 es true si índice >= size/2
  vmovdqa ymm10, ymm14
  vcmppd ymm10, ymm2, 0x1                ; ymm10 es true si índice <= -size/2
  vorpd ymm9, ymm10, ymm11             ; todos los que modificamos
  vcmppd ymm8, ymm8, 0x8              ; set to 1 all bits
  vxorpd ymm9, ymm9, ymm8         ; todos los que no modificamos
  
; ymm11 son ind > size/2; ymm10 son ind < -size/2; ymm9 son ind no modif
  
  ;; índices tienen que ir a valor
  vmovdqa ymm13, ymm11
  vmovdqa ymm12, ymm10
  vandpd ymm9, ymm14    ; ymm14 son LOS VALORES que no modificamos
  vandpd ymm12, ymm14                   ; (comparar con vpand)
  vandpd ymm13, ymm14                   ;
  
; ymm14 val no modif; ymm13 son val < -size/2; ymm12 son val > size/2
  
  vsubpd ymm13, size
  vandpd ymm11, ymm13
  vaddpd ymm12, size
  vandpd ymm10, ymm12

  vaddpd ymm9, ymm10
  vaddpd ymm9, ymm11       ; esto para juntarlos porque sabemos que son 0 los cruzados
  
  vmovdqu [dr_p], ymm9


ret
