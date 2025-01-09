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

tableau_x_foyers: resd 8000
tableau_y_foyers: resd 8000
drawing_done:   resb 1 ; Flag to indicate if drawing is done


section .data

; Format strings

affichage_indice db "Indice : %d", 10, 0 ; Format string for printf
error_message db "Erreur : indice hors limites ou accès invalide.", 0xA, 0  ; Message d'erreur avec saut de ligne
event:          times 24 dq 0

width          dd 800
height         dd 800
nb_points      dd 100000
nb_foyers      dd 80

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

    ; r14 est à 0 il servira de compteur
    xor r14, r14

    boucle_foyers:
        mov ecx, [width] 
        call generate_random

        ; Sauvegarder le nombre aléatoire
        mov [tableau_x_foyers + r14 * 4], r12

        mov ecx, [height] 
        call generate_random

        ; Sauvegarder le nombre aléatoire
        mov [tableau_y_foyers + r14 * 4], r12


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

;#########################################
;# BEGIN DRAWING ZONE                    #
;#########################################


    xor r14, r14

    jmp boucle_points

; generation aléatoire de 10000 points
; pas besoin de sauvegarder les points il seron traités un à un
; r14 a 0 il servira de compteur

boucle_points:

    
    mov ecx, [width]
    call generate_random


    ; Sauvegarder le nombre aléatoire dans x1
    mov [x1], r12d

    mov ecx, [height]
    call generate_random

    ;sauvegarder le nombre aléatoire dans y1
    mov [y1], r12


    ; trouver de quelle foyer le point est le plus proche
    ; r15d est à 0 il servira de compteur

    xor r15d, r15d ; indice du foyer
    ; boucle qui parcourt les foyers et calcule la distance entre le points et les foyers

    ; initialiser la distance à la plus grande valeur possible
    mov dword [distance_min], 0xffffff

    boucle_foyers_point:

        ; calcul de la distance entre le point et le foyer

        ; récupérer les coordonnées du foyer
        ; et les stocker dans rcx et rdx
        mov rdi, [tableau_x_foyers + r15d * 4]
        mov rsi, [tableau_y_foyers + r15d * 4]
        mov rdx, [x1]
        mov rcx, [y1]
        call calc_distance

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

    mov rbp, [distance_min_id]


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

    cmp r14d, [nb_points]
    jl boucle_points
    jmp flush



sauvegarde_distance:

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

generate_random:
    ; Inputs:
    ; ecx - maximum value
    ; Output:
    ; r12 - random number between 0 and r12-1

    rdrand r12d         ; genere un nombre aléatoire

    ; check si le flag de carry est à 0
    jnc generate_random


    ; r12d contient un nombre aléatoire
    ; modulo avec ecx pour obtenir un nombre entre 0 et ecx-1
    xor edx, edx        ; Clear edx
    mov eax, r12d       
    div ecx             ; eax = eax % ecx

    ; retourne le nombre aléatoire dans r12d
    mov r12d, edx

    ret

; fonction calcule la distance entre deux points
calc_distance:
    ; Inputs:
    ; rdi - x1 (coordinate of the first point)
    ; rsi - y1 (coordinate of the first point)
    ; rdx - x2 (coordinate of the second point)
    ; rcx - y2 (coordinate of the second point)
    ; Output:
    ; r12d - distance between the two points

    ; calcul de la distance en x
    mov r12, rdi
    sub r12, rdx
    imul r12, r12
    mov eax, r12d

    ; calcul de la distance en y
    mov r12, rsi
    sub r12, rcx
    imul r12, r12
    add eax, r12d

    ; calcul de la distance totale
    mov r12d, eax
    call int_sqrt

    ret