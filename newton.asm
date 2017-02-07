default rel
global minimum_images

section .data
mask_bc:  db 0, 0, 0, 0xFF
mask_ones:   dq 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF 

section .text


;; int newton(int n_particles, double size, double *position,
;;                   RDI     ,        XMM0,           RSI   ,
;;            double *velocity, double *force, double *potential)
;;                      RDX   ,          RCX ,            R8

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
  vbroadcastsd ymm1, xmm0 ; ymm1 es size en todos lados
  vbroadcastsd ymm2, xmm2 ; ymm2 es 2.0 en todos lados
  vdivpd ymm1, ymm1, ymm2 ; ymm1 es size/2 en todos lados

  
  ;; -1/2
  mov r9, -1
  cvtsi2sd xmm3, r9
  vbroadcastsd ymm3, xmm3 ; ymm3 es -1.0 en todos lados
  vmulpd ymm2, ymm1, ymm3 ; ymm2 es -size/2 en todos lados

  mov rax, 24
  mul i                                   ; 24 = 3 (DIM) * 8 (size)
  vmovdqu ymm15, [position_p + rax]       ; unaligned es lento

  mov rax, 24
  mul j                                   ; 24 = 3 (DIM) * 8 (size)
  vmovdqu ymm14, [position_p + rax]       ; unaligned es lento
  
  vsubpd ymm14, ymm15                    ; ymm14 es posición j - i
  vmovdqa ymm13, ymm14
  vcmppd ymm13, ymm1, 0xD                ; mayor o igual a size/2
  vmovdqa ymm12, ymm14
  vcmppd ymm12, ymm2, 0x1                ; menor a -size/2
  vmovdqa ymm11, ymm13
  vmovdqa ymm10, ymm12
  vandpd ymm12, ymm14                   ; (comparar con vpand)
  vandpd ymm13, ymm14                   ;

  vpand ymm9, ymm12, ymm13             ; todos los que modificamos
  vxorps ymm9, ymm9, [mask_ones]         ; todos los que no modificamos
  
  vpand ymm14, ymm9    ; ymm14 son LOS VALORES que no modificamos
  vsubpd ymm13, size
  vandpd ymm11, ymm13
  vaddpd ymm12, size
  vandpd ymm10, ymm12

  vaddpd ymm14, ymm10
  vaddpd ymm14, ymm12       ; esto para juntarlos porque sabemos que son 0 los cruzados
  
  vmovdqu [dr_p], ymm14

ret
