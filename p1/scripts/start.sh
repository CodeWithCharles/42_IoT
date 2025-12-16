#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              CONFIGURATION                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

BOX_WIDTH=24

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                           FONCTIONS UTILITAIRES                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Centrer du texte dans une ligne de boîte
# Usage: center_text "texte" [largeur]
center_text() {
    local text="$1"
    local width="${2:-$BOX_WIDTH}"
    local text_len=${#text}
    local padding=$(( (width - text_len) / 2 ))
    local padding_right=$(( width - text_len - padding ))
    printf "║%*s%s%*s║\n" $padding "" "$text" $padding_right ""
}

# Aligner le texte à gauche dans une ligne de boîte
# Usage: left_text "texte" [largeur]
left_text() {
    local text="$1"
    local width="${2:-$BOX_WIDTH}"
    local text_len=${#text}
    local padding_right=$(( width - text_len ))
    printf "║%s%*s║\n" "$text" $padding_right ""
}

# Afficher une bordure horizontale
# Usage: box_line "top" | "middle" | "bottom"
box_line() {
    local line=""
    for ((i=0; i<BOX_WIDTH; i++)); do line+="═"; done
    case "$1" in
        top)    echo "╔${line}╗" ;;
        middle) echo "╠${line}╣" ;;
        bottom) echo "╚${line}╝" ;;
    esac
}

# Attendre une touche
wait_key() {
    local msg="${1:-Appuyez sur une touche...}"
    echo ""
    echo "$msg"
    read -rsn1
}

# Vérifier si les VMs sont en cours d'exécution
vms_running() {
    vagrant status 2>/dev/null | grep -q "running"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              MENU INTERACTIF                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Menu interactif avec navigation clavier
# Usage: menu_select "Titre" "nom1:fonction1" "nom2:fonction2" ...
# Retour: Exécute la fonction associée à l'option sélectionnée
# Navigation: ↑/↓ pour naviguer, Entrée pour sélectionner, q/Backspace pour revenir
menu_select() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    local count=${#options[@]}

    # Cacher le curseur
    tput civis
    trap 'tput cnorm' EXIT

    # Afficher le menu
    _draw_menu() {
        clear
        box_line "top"
        center_text "$title"
        box_line "middle"
        
        for i in "${!options[@]}"; do
            local name="${options[$i]%%:*}"
            if [[ $i -eq $selected ]]; then
                left_text " ➤ $name"
            else
                left_text "   $name"
            fi
        done
        box_line "bottom"
    }

    # Boucle principale
    while true; do
        _draw_menu
        read -rsn1 key
        
        case "$key" in
            $'\x1b')  # Flèches directionnelles
                read -rsn2 key
                case "$key" in
                    '[A') ((selected--)); [[ $selected -lt 0 ]] && selected=$((count - 1)) ;;
                    '[B') ((selected++)); [[ $selected -ge $count ]] && selected=0 ;;
                esac
                ;;
            '')  # Entrée
                local func="${options[$selected]#*:}"
                clear
                if [[ "$func" == "return" ]]; then
                    return 0
                fi
                eval "$func"
                # wait_key
                ;;
            'q'|'Q'|$'\x7f')  # Quitter / Backspace
                tput cnorm
                clear
                return 0
                ;;
        esac
    done
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                 ACTIONS                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Action: Lancer / Gérer les VMs
action_run() {
    if vms_running; then
        menu_select "VMs running" \
            "Status:make status" \
            "SSH:action_ssh" \
            "Back:return"
    else
        make up
    fi
}

# Action: Détruire les VMs
action_down() {
    menu_select "Destroy VMs?" \
        "Yes:make down" \
        "No:return"
}

# Action: Connexion SSH
action_ssh() {
    if ! vms_running; then
        echo "No VMs are running. Please start the VMs first."
        return
    fi
    menu_select "Select Machine" \
        "Server:make ssh-server" \
        "Worker:make ssh-worker" \
        "Back:return"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                   MAIN                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

main() {
    menu_select "Welcome to IOT" \
        "Run:action_run" \
        "Down:action_down" \
        "SSH:action_ssh" \
        "Exit:return"
}

# Lancer le programme
main
