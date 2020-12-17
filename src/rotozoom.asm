                .model tiny, pascal
                .386
                .dosseg
                option proc: private


;;::::::::
vgaGetMode      proto   near
vgaSetMode      proto   near, :byte
vgaSetPal       proto   near, ppal:near ptr, entries:word
rotozoom        proto   near angle:real4, pbitmap:near ptr byte

;;::::::::
.const
include mario.inc

_180            real8   180.0
_65536          real8   65536.0
_pi             real8   3.14159265359
_step           real8   0.1


;;::::::::
.code
.startup
main            proc    near
                local   vdo_mode_no: byte, angle:real4

                ;; Get default video mode
                call    vgaGetMode
                mov     vdo_mode_no, al

                ;; Set mode 13h & palette
                invoke  vgaSetMode, 13h
                invoke  vgaSetPal, offset image_pal, 256

                ;; Loop
                mov     angle, 0
@@:
                invoke  rotozoom, angle, offset image_data
                fld     angle
                fadd    _step
                fstp    angle

                ;; Check for keypress
                mov     ah, 01h
                int     16h
                jz      @B

                ;; Exit to dos
@exit:          invoke  vgaSetMode, vdo_mode_no
                mov     ax, 04c00h
                int     21h
main            endp


;:::::
vgaGetMode      proc    near
                mov     ah, 0Fh
                int     10h
                ret
vgaGetMode      endp


;:::::
vgaSetMode      proc    near,
                        mode_no:byte

                xor     ax, ax
                mov     al, mode_no
                int     10h
                ret

vgaSetMode      endp


;:::::
vgaSetPal       proc    near uses si ax cx,
                        ppal:near ptr,
                        entries:word

                xor     al, al
                mov     dx, 3c8h
                out     dx, al
                inc     dx

                mov     si, ppal
                mov     cx, entries
                shl     cx, 1
                add     cx, entries
                rep     outsb

                ret
vgaSetPal       endp


;:::::::
rotozoom        proc    near public uses ds es di si,
                        angle:real4,
                        pbitmap:near ptr byte

                local   y:word,\
                        u:dword, v:dword,\
                        dudx:dword, dvdx:dword,\
                        dudx_s:dword, dvdx_s:word

                ;; ds:si -> Texture
                mov     si, pbitmap

                ;; es:[di] -> VRAM
                xor     di, di
                mov     ax, 0a000h
                mov     es, ax

                xor     eax, eax
                mov     u, eax
                mov     v, eax

                ;; c = cos(angle*PI/180)
                ;; s = sin(angle*PI/180)
                fld     angle           ; angle
                fmul    _pi             ; angle*pi
                fdiv    _180            ; angle*pi/180
                fsincos                 ; c s
                ;; dudx = c*(s+1)
                ;; dvdx = s*(s+1)
                fld     st(1)           ; s c s
                fld1                    ; 1 s c s
                faddp   st(1), st(0)    ; (s+1) c s
                fmul    _65536          ; (s+1)*65536 c s
                fld     st(0)           ; (s+1)*65536 (s+1)*65536 s c
                fmulp   st(3), st(0)    ; (s+1) s dudx*65536
                fmulp   st(1), st(0)    ; dvdx*65536 dudx*65536
                fistp   dvdx            ; dudx*65536
                fistp   dudx            ;

                ;; Self modifying code magic
                ;;
                ;; c1 = ffffffff:ffffffff:iiiiiiii:iiiiiiii  (dudx 16.16)
                ;; c2 = iiiiiiii:ifffffff  (dvdx 9.7)
                mov     ebx, dudx
                ror     ebx, 16
                mov     dword ptr cs:[@c1_fixup+2], ebx
                mov     ebx, dvdx
                shr     ebx, 16-7
                mov     word ptr cs:[@c2_fixup+2], bx

                ;; for y = 0 to 199
                mov     y, -200
@loop:
                ;; eax    = ffffffff:ffffffff:iiiiiiii:iiiiiiii  (u 16.16)
                ;; cx     = iiiiiiii:ifffffff  (v 9.7)
                mov     eax, u
                ror     eax, 16
                mov     ecx, v
                shr     ecx, 16-7

                ;; for x = 0 to 319
                mov     dx, -320
@@:
                and     ax, 127
                mov     bx, cx
                and     bx, 127 shl 7
                or      bx, ax
                mov     bl, ds:[si+bx]
                mov     es:[di], bl
                inc     di

                ;; u1 = u1 + c1
                ;; v1 = v1 + c2
@c1_fixup:      add     eax, 0deadbeefh
                adc     ax, 0
@c2_fixup:      add     cx, 0deadh

                inc     dx
                jnz     @B

               ;; u = u - dvdx
               ;; v = v + dudx
                mov     eax, dvdx
                mov     ebx, dudx
                sub     u, eax
                add     v, ebx

                inc     y
                jnz     @loop

@exit:
                ret
rotozoom        endp

END