#!/bin/sh
# Surveillance du Home Assistant du Raspberry Pi, depuis le NAS Synology.
#
# À installer dans DSM : Panneau de configuration > Planificateur de tâches
#   > Créer > Tâche planifiée > Script défini par l'utilisateur
#   Utilisateur       : root
#   Planification     : tous les jours, répéter toutes les 5 minutes
#   Paramètres de tâche : cocher « Envoyer les détails de l'exécution par e-mail »
#                         ET « uniquement si le script se termine anormalement »
#
# Le script sort en code 1 UNIQUEMENT au moment où la perte est confirmée,
# ce qui déclenche l'e-mail DSM une seule fois par panne — pas toutes les
# 5 minutes. Il notifie aussi le retour à la normale.
#
# Ne démarre PAS le conteneur du NAS : les deux instances ne doivent jamais
# tourner en même temps (conflit KNX, double écriture). Il te dit quoi faire.

HOTE="192.168.0.95"
PORT="8123"
SEUIL=3                       # 3 échecs consécutifs = 15 min avant alerte
ETAT="/volume2/docker/ha-watchdog"
ECHECS="$ETAT/echecs"
ALERTE="$ETAT/alerte_envoyee"

mkdir -p "$ETAT" 2>/dev/null
[ -f "$ECHECS" ] || echo 0 > "$ECHECS"

notifier() {
    # $1 = titre, $2 = message
    #
    # Le canal d'alerte est l'e-mail du planificateur DSM : tout ce qu'on
    # ecrit sur la sortie standard atterrit dans le corps du message.
    # (synodsmnotify a ete retire : DSM refuse un titre en texte libre,
    #  « is neither mail string key nor i18n format », et l'erreur polluait
    #  le mail. L'e-mail arrivant sur un compte releve par le telephone,
    #  la notification push etait de toute facon redondante.)
    #
    # Pour ajouter un push dedie (ntfy, Pushover...), une ligne curl ici
    # suffit — elle n'a pas besoin de Home Assistant, qui est justement mort.
    logger -t ha-watchdog "$1 - $2"
    echo "$1"
    echo "$2"
}

# --- Test principal : Home Assistant répond-il en HTTP ? -------------------
if curl -s -f -o /dev/null --max-time 10 "http://$HOTE:$PORT/manifest.json"; then
    if [ -f "$ALERTE" ]; then
        rm -f "$ALERTE"
        notifier "Home Assistant est de retour" \
"Le Pi ($HOTE) repond a nouveau sur le port $PORT.

Si tu avais demarre l'instance du NAS, ARRETE-LA avant de reutiliser le Pi :
  docker stop homeassistant

Les deux instances ne doivent jamais tourner ensemble."
    fi
    echo 0 > "$ECHECS"
    exit 0
fi

# --- Échec : on incrémente le compteur ------------------------------------
N=$(cat "$ECHECS" 2>/dev/null || echo 0)
N=$((N + 1))
echo "$N" > "$ECHECS"

if [ "$N" -lt "$SEUIL" ]; then
    logger -t ha-watchdog "echec $N/$SEUIL sur $HOTE:$PORT"
    exit 0
fi

[ -f "$ALERTE" ] && exit 0     # alerte deja envoyee pour cette panne

# --- Perte confirmée : on distingue les deux cas --------------------------
touch "$ALERTE"

if ping -c 2 -W 3 "$HOTE" >/dev/null 2>&1; then
    DIAG="La machine repond au ping mais pas Home Assistant.
=> Le Raspberry Pi est vivant, c'est Home Assistant qui est plante.
   Essaie d'abord de le redemarrer depuis l'interface si elle repond,
   ou attends : il peut se relever seul."
else
    DIAG="La machine ne repond meme pas au ping.
=> Le Raspberry Pi est HS (probablement le bug USB RTL9210).
   Seul un debranchement/rebranchement physique le relancera."
fi

notifier "Home Assistant injoignable depuis $((SEUIL * 5)) min" \
"Le Pi ($HOTE) ne repond plus sur le port $PORT.

$DIAG

POUR BASCULER SUR LE NAS (uniquement si le Pi est bien HS) :
  docker start homeassistant
puis http://<ip-du-nas>:8123

Verifie que le Pi est reellement arrete avant : les deux instances
ne doivent jamais tourner en meme temps (conflit KNX)."

exit 1
