; External functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XDrawPoint
extern XNextEvent

; External functions from stdio library (ld-linux-x86-64.so.2)    
extern printf
extern exit

%define StructureNotifyMask 131072
%define KeyPressMask         1
%define ButtonPressMask      4
%define MapNotify           19
%define KeyPress             2
%define ButtonPress          4
%define Expose              12
%define ConfigureNotify     22
%define CreateNotify        16
%define QWORD                8
%define DWORD                4
%define WORD                 2
%define BYTE                 1

global main

section .bss

display_name:   resq 1
screen:         resd 1
depth:          resd 1
connection:     resd 1
window:         resq 1
gc:             resq 1

distance_min:   resd 1
distance_min_id:resd 1
nb_points:      resd 1
nb_foyers:      resd 1
tableau_x_foyers: resd 800
tableau_y_foyers: resd 800
tableau_color_foyers: resd 800
drawing_done:   resb 1 ; Flag to indicate if drawing is done


section .data

; Format strings

affichage_ligne db " ligne de %d;%d a %d;%d ", 10 , 0 
affichage_indice db "Indice : %d", 10, 0 ; Format string for printf
affichage_indice_point db "Indice_pts : %d", 10, 0 ; Format string for printf
affichage_distance db "Distance : %d", 10, 0 ; Format string for printf
affichage_distance_min db "Distance min : %d", 10, 0 ; Format string for printf
affichage_x db "x : %d", 10, 0 ; Format string for printf
affichage_y db "y : %d", 10, 0 ; Format string for printf
error_message db "Erreur : indice hors limites ou accès invalide.", 0xA, 0  ; Message d'erreur avec saut de ligne
dubug_print_2 db "BEGIN GENERATION OF FOYERS", 10 , 0
dubug_print_3 db "END GENERATION OF FOYERS", 10 , 0
dubug_print_4 db "BEGIN DRAWING ZONE", 10 , 0
dubug_print_5 db "END DRAWING ZONE", 10 , 0
nb_foyers_str db "Number of foyers: %d", 10, 0 ; Format string for printf (%d for integer, 10 for newline)
nl db 10, 0 ; Newline character
separator db "--------------------------------", 10, 0 ; Separator for debug messages
event:          times 24 dq 0

width          dd 800
height         dd 800

x1:             dd 0
x2:             dd 0
y1:             dd 0
y2:             dd 0

section .text

;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
    mov     byte [drawing_done], 0
    mov     rdi,0
    xor     rax, rax

    mov     qword[display_name],rax	; rax=nom du display

    call    XOpenDisplay	; Création de display


    ; display_name structure
    ; screen = DefaultScreen(display_name);
    mov     [display_name],rax
    mov     eax,dword[rax+0xe0]
    mov     dword[screen],eax

    mov rdi,qword[display_name]
    mov esi,dword[screen]
    call XRootWindow
    mov rbx,rax

    mov rdi,qword[display_name]
    mov rsi,rbx
    mov rdx,10
    mov rcx,10
    mov r8,[width]	; largeur
    mov r9,[height]	; hauteur
    push 0xFFFFFF	; background  0xRRGGBB
    push 0x00FF00
    push 1
    call XCreateSimpleWindow
    mov qword[window],rax

    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,131077 ;131072
    call XSelectInput

    mov rdi,qword[display_name]
    mov rsi,qword[window]
    call XMapWindow

    mov rsi,qword[window]
    mov rdx,0
    mov rcx,0
    call XCreateGC
    mov qword[gc],rax


boucle: ; Event handling loop
    mov     rdi, qword[display_name]
    mov     rsi, event
    call    XNextEvent

    cmp     dword[event], ConfigureNotify ; On window appearance
    je      foyers                        ; Jump to 'foyers' label

    cmp     dword[event], KeyPress        ; On key press
    je      closeDisplay                  ; Jump to 'closeDisplay'
    jmp     boucle

;#########################################
;# BEGIN GENERATION OF FOYERS            #
;#########################################
    

foyers:

    cmp     byte [drawing_done], 1
    je      boucle ; If drawing is done, skip the drawing process
    ;mov rdi, dubug_print_2   ; printf "PROGRAMME PRINCIPAL"
    ;call printf
    ;xor eax, eax


    ; Sauvegarder le nombre aléatoire
    mov dword [nb_foyers], 80
    ; Afficher le nombre de foyers dans le terminal
    mov rdi, nb_foyers_str  
    mov rsi, [nb_foyers] 
    call printf
    xor eax, eax



    ; r14 est à 0 il servira de compteur
    xor r14, r14

    boucle_foyers:

        ;affichage_indice_point
        mov rdi, affichage_indice
        mov rsi, r14
        call printf
        xor eax, eax



        ; Lire l'horodatage avec RDTSC
        rdtsc
        call int_sqrt
        ; r12 contient la partie basse de l'horodatage
        ; Prendre le reste de la division par 401 pour limiter à [0, 400]
        mov ecx, [width]
        xor edx, edx      ; EDX est à 0 pour div
        div ecx           ; r12 / ECX -> Quotient dans r12, reste dans EDX
        mov r12d, edx      ; Le résultat (reste) est dans r12

        ; Sauvegarder le nombre aléatoire
        mov [tableau_x_foyers + r14 * 4], r12

        ; affichage_x
        mov rdi, affichage_x
        mov rsi, r12
        call printf
        xor eax, eax



        ; Lire l'horodatage avec RDTSC
        rdtsc
        ; r12 contient la partie basse de l'horodatage
        ; Prendre le reste de la division par 401 pour limiter à [0, 400]
        mov ecx, [height]
        xor edx, edx      ; EDX est à 0 pour div
        div ecx           ; r12 / ECX -> Quotient dans r12, reste dans EDX
        mov r12d, edx      ; Le résultat (reste) est dans r12

        ; Sauvegarder le nombre aléatoire
        mov [tableau_y_foyers + r14 * 4], r12

        mov rdi, affichage_y
        mov rsi, r12
        call printf
        xor eax, eax



        mov rdi, nl
        call printf
        xor eax, eax

        ;generer une couleur aleatoire
        ;choisir un nombre entre 0 et nb_colors-1
        mov r12, 0xFFFFFF
        rdtsc
        xor rdx, rdx
        div r12
        mov r12, rdx

        ;sauvegarder la couleur
        mov [tableau_color_foyers + r14 * 4], r12d
        


        mov rdi, nl
        call printf
        xor eax, eax



        ; Incrémenter le compteur
        inc r14

        ; Si le compteur est inférieur au nombre de foyers, on boucle
        cmp r14d, [nb_foyers]
        jl boucle_foyers
        ;dec r14d
        ;mov [nb_foyers], r14d

;#########################################
;# END GENERATION OF FOYERS              #
;#########################################
    mov rdi, separator
    call printf
    xor eax, eax


;#########################################
;# BEGIN DRAWING ZONE                    #
;#########################################

    xor r13, r13 ; r13 est à 0 il servira de compteur pour les foyers
    xor r14, r14 ; r14 est à 0 il servira de compteur pour x
    xor r15, r15 ; r15 est à 0 il servira de compteur pour y
    boucle_x:
        xor r15, r15 ; r15 est à 0 il servira de compteur pour y

        boucle_y:   
            xor r13, r13 ; r13 est à 0 il servira de compteur pour les foyers
            mov dword [distance_min], 0xffffff

            boucle_foyers_enum:

                ; énumérer les foyers
                ; sauvegarder les coordonnées du foyer le plus proche du point r14, r15
                ; sauvegarder la distance entre le point r14, r15 et le foyer le plus proche

                ; calcul de la distance entre le point et le foyer
                ; calcul de la distance en x
                mov r12, [tableau_x_foyers + r13 * 4]
                sub r12, r14
                imul r12, r12
                mov ecx, r12d

                ; calcul de la distance en y
                mov r12, [tableau_y_foyers + r13 * 4]
                sub r12, r15
                imul r12, r12
                add ecx, r12d

                ; calcul de la distance totale
                mov r12d, ecx
                call int_sqrt

                ; si r12d est inférieur à distance_min, on sauvegarde la distance et l'identifiant du foyer


                cmp r12d,[distance_min]
                jl sauvegarde_distance
                suit_boucle_foyers_enum:


                inc r13
                cmp r13d, [nb_foyers]
                jl boucle_foyers_enum


                ;couleur du point
                xor r13, r13
                mov r13d ,[distance_min_id]

                mov rdi,qword[display_name]
                mov rsi,qword[gc]
                mov edx,[tableau_color_foyers + r13d * 4]
                call XSetForeground
                mov rdi,qword[display_name]
                mov rsi,qword[window]
                mov rdx,qword[gc]
                mov rcx,r15	; coordonnée en x
                mov r8,r14	; coordonnée en y
                call XDrawPoint

                



            inc r15d
            cmp r15d, [width]
            jl boucle_y


        inc r14d
        cmp r14d, [height]
        jl boucle_x

        jmp flush






sauvegarde_distance:
    
    ; sauvegarder la distance et l'identifiant du foyer
    mov [distance_min], r12
    mov [distance_min_id], r13

    jmp suit_boucle_foyers_enum


; ############################
; # END DRAWING ZONE         #
; ############################

flush:
    mov     byte [drawing_done], 1
    mov rdi,qword[display_name]
    call XFlush
    jmp boucle
    mov rax,34
    syscall


closeDisplay:
    mov     rax, qword[display_name]
    mov     rdi, rax
    call    XCloseDisplay
    xor     rdi, rdi
    call    exit

; Function: int_sqrt
; Description: Computes the integer square root of a non-negative integer.
; Input: r12 contains the input number (unsigned).
; Output: r12 contains the integer square root.

section .text
global int_sqrt

int_sqrt:
    ; Calcul de la racine carrée entière de r12
    ; Entrée : r12
    ; Sortie : r12

    mov ecx, 0          ; compteur
    mov ebx, r12d        ; valeur initiale

sqrt_loop:
    inc ecx             ; incrémenter le compteur
    mov edx, ecx
    imul edx, edx       ; edx = ecx * ecx
    cmp edx, ebx        ; comparer edx avec la valeur initiale
    jg sqrt_done        ; si edx > ebx, terminer la boucle
    jmp sqrt_loop       ; sinon, continuer la boucle

sqrt_done:
    dec ecx             ; décrémenter le compteur pour obtenir la racine carrée
    mov r12d, ecx        ; stocker le résultat dans r12
    ret

erreur:
    ; Afficher l'indice de r12 
    mov    rdi, affichage_indice
    mov    rsi, r12
    xor    eax, eax
    call   printf

    mov     rdi, error_message         ; Préparer un message d'erreur
    xor     eax, eax
    call    printf                     ; Afficher l'erreur
    jmp     closeDisplay              ; Aller à la fin pour éviter d'autres instructions
