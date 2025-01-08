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
tableau_x_foyers: resd 8000
tableau_y_foyers: resd 8000
drawing_done:   resb 1 ; Flag to indicate if drawing is done


section .data

; Format strings

affichage_ligne db " ligne de %d;%d a %d;%d ", 10 , 0 
affichage_indice db "Indice : %d", 10, 0 ; Format string for printf
affichage_indice_point db "Indice_pts : %d", 10, 0 ; Format string for printf
affichage_distance db "Distance : %d", 10, 0 ; Format string for printf
affichage_x db "x : %d", 10, 0 ; Format string for printf
affichage_y db "y : %d", 10, 0 ; Format string for printf
affichage_distance_min db "Distance_min : %d", 10, 0 ; Format string for printf
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
    push 0x000000	; background  0xRRGGBB
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


    xor r14, r14

    jmp boucle_points

; generation aléatoire de 10000 points
; pas besoin de sauvegarder les points il seron traités un à un
; r14 a 0 il servira de compteur

boucle_points:
    ;separation


    mov rdi, separator
    xor eax, eax
    call printf




    ;affichage_indice_point
    mov rdi, affichage_indice_point
    mov rsi, r14
    xor eax, eax
    call printf
    



    ; generation de x pour le point
    ; Lire l'horodatage avec RDTSC
    rdtsc
    ; r12 contient la partie basse de l'horodatage
    ; Prendre le reste de la division par 401 pour limiter à [0, 400]
    mov ecx, [width]
    xor edx, edx      ; EDX est à 0 pour div
    div ecx           ; r12 / ECX -> Quotient dans r12, reste dans EDX
    mov r12d, edx      ; Le résultat (reste) est dans r12

    ; Sauvegarder le nombre aléatoire dans x1
    mov [x1], r12d

    ;affichage_x
    mov rdi, affichage_x
    mov rsi, r12
    xor eax, eax
    call printf



    ; generation de y pour le point
    ; Lire l'horodatage avec RDTSC
    rdtsc
    ; r12 contient la partie basse de l'horodatage
    ; Prendre le reste de la division par 401 pour limiter à [0, 400]
    mov ecx, [height]
    xor edx, edx      ; EDX est à 0 pour div
    div ecx           ; r12 / ECX -> Quotient dans r12, reste dans EDX
    mov r12d, edx      ; Le résultat (reste) est dans r12

    ;sauvegarder le nombre aléatoire dans y1
    mov [y1], r12

    ;affichage_y
    mov rdi, affichage_y
    mov rsi, r12
    xor eax, eax
    call printf



    ;nl
    mov rdi, nl
    xor eax, eax
    call printf




    ; trouver de quelle foyer le point est le plus proche
    ; r15d est à 0 il servira de compteur

    xor r15d, r15d ; indice du foyer
    ; boucle qui parcourt les foyers et calcule la distance entre le points et les foyers

    ; initialiser la distance à la plus grande valeur possible
    mov dword [distance_min], 0xffffff

    boucle_foyers_point:


        ; calcul de la distance entre le point et le foyer
        ; calcul de la distance en x
        mov r12, [tableau_x_foyers + r15d * 4]
        sub r12, [x1]
        imul r12, r12
        mov ecx, r12d

        ; calcul de la distance en y
        mov r12, [tableau_y_foyers + r15d * 4]
        sub r12, [y1]
        imul r12, r12
        add ecx, r12d

        ; calcul de la distance totale
        mov r12d, ecx
        call int_sqrt

        ; si aex est inférieur à distance_min, on sauvegarde la distance et l'identifiant du foyer

        cmp r12d,[distance_min]
        jl sauvegarde_distance

        suite_boucle_foyers_point:

        ; incrementer le compteur
        inc r15d

        ; si le compteur est inférieur au nombre de foyers, on boucle




        cmp r15d, [nb_foyers]
        jl boucle_foyers_point



    ; dessiner le point avec le foyer le plus proche
    ; on a l'id du foyer le plus proche dans distance_min_id
    ; on a les coordonnées du point dans x1 et y1
    ; on a les coordonnées du foyer dans tableau_x_foyers[distance_min_id] et tableau_y_foyers[distance_min_id]

    ; id et coordonnées du foyer le plus proche
    ;affichage_indice
    mov rdi, affichage_indice
    mov rsi, [distance_min_id]
    xor eax, eax
    call printf



    mov rbp, [distance_min_id]
    ;affichage_x
    mov rdi, affichage_x
    mov rax, [tableau_x_foyers + rbp * 4]
    mov rsi, rax
    xor eax, eax
    call printf



    ;affichage_y
    mov rdi, affichage_y
    mov rax, [tableau_y_foyers + rbp * 4]
    mov rsi, rax
    xor eax, eax
    call printf



    ;nl
    mov rdi, nl
    xor eax, eax
    call printf



    ;affichage_distance
    ;mov rdi, [distance_min]
    ;mov rsi, r12
    ;call printf
    ;xor eax, eax



    ;nl
    mov rdi, nl
    xor eax, eax
    call printf



    ;separation
    mov rdi, separator
    xor eax, eax
    call printf




   ;couleur de la ligne 4
    mov rdi,qword[display_name]
    mov rsi,qword[gc]
    mov edx,0xFF00FF	; Couleur du crayon ; violet
    call XSetForeground
    ; récupérer les coordonnées du foyer le plus proche son id est dans distance_min_id
    mov r12d, [distance_min_id]


    ;si r12d est supérieur à 399, on affiche un message d'erreur
    cmp r12d, [nb_foyers]
    jg erreur

    

    mov eax, [tableau_x_foyers + r12d * 4]
    mov dword[x2], eax
    mov eax, [tableau_y_foyers + r12d * 4]
    mov dword[y2], eax

    ; dessin de la ligne 4
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,qword[gc]
    mov ecx,dword[x1]	; coordonnée source en x
    mov r8d,dword[y1]	; coordonnée source en y
    mov r9d,dword[x2]	; coordonnée destination en x
    push qword[y2]		; coordonnée destination en y
    call XDrawLine



    ; Incrementer le compteur (indice du point)
    inc r14

    ; Si le compteur est inférieur au nombre de points, on boucle

    cmp r14, 100000
    jl boucle_points
    jmp flush



sauvegarde_distance:


    ; afficher de affichage_dist_l_min
    ;mov rdi, affichage_dist_l_min
    ;mov rsi, r12
    ;mov rdx, [distance_min]
    ;xor eax, eax
    ;call printf



    ;affichage de l'id "distance_min_id"
    ;mov rdi, affichage_indice
    ;mov rsi, r15
    ;xor eax, eax
    ;call printf


    
    ; sauvegarder la distance et l'identifiant du foyer
    mov [distance_min], r12
    mov [distance_min_id], r15d

    jmp suite_boucle_foyers_point

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
