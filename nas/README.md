# Surveillance du Pi depuis le NAS Synology

`watchdog-ha.sh` vérifie toutes les 5 minutes que Home Assistant répond sur le
Raspberry Pi (`192.168.0.95:8123`) et prévient quand ce n'est plus le cas.

Il ne répare rien — il n'y a pas de prise commandée sur le Pi. Son rôle est de
te dire, sans que tu aies à t'en apercevoir toi-même, qu'il faut basculer sur
l'instance du NAS.

## Ce qu'il fait

| Situation | Comportement |
|---|---|
| HA répond | Rien, compteur remis à zéro |
| 1er et 2e échec | Rien (journalisé seulement) — évite les faux positifs |
| 3e échec consécutif (15 min) | **Alerte**, une seule fois, code de sortie 1 |
| Échecs suivants | Silence — pas de répétition |
| HA revient | Notification de retour + rappel d'arrêter le conteneur du NAS |

## Le diagnostic dans l'alerte

Le script teste d'abord le port 8123, puis le ping. La combinaison distingue
les deux pannes, et donc la conduite à tenir :

- **Ping OK, port 8123 muet** → le Pi est vivant, c'est Home Assistant qui est
  planté. Il peut se relever seul.
- **Ping muet** → le Pi est HS (typiquement le bug USB RTL9210). Seul un
  débranchement/rebranchement le relancera. C'est le cas du 30 août 2026.

## Pourquoi pas un démarrage automatique du conteneur

Les deux instances ne doivent **jamais** tourner en même temps : conflit sur le
bus KNX et double écriture. Un simple faux positif réseau suffirait à créer ce
doublon. Le script donne la commande, la décision reste humaine.

## Installation dans DSM

1. **Panneau de configuration → Notification → E-mail** : vérifier qu'une
   adresse est configurée et fonctionnelle. C'est le canal de l'alerte.
2. Copier `watchdog-ha.sh` sur le NAS, ou coller son contenu directement à
   l'étape suivante.
3. **Panneau de configuration → Planificateur de tâches → Créer → Tâche
   planifiée → Script défini par l'utilisateur**
   - **Général** — Utilisateur : `root`
   - **Planification** — Tous les jours, *Répéter toutes les 5 minutes*
   - **Paramètres de tâche** — coller le script dans « Commande définie par
     l'utilisateur » ; cocher **« Envoyer les détails de l'exécution par
     e-mail »** *et* **« uniquement si le script se termine anormalement »**
4. Clic droit sur la tâche → **Exécuter** pour un test à blanc. Le Pi étant en
   ligne, elle doit se terminer sans rien envoyer.

## Vérifier qu'il fonctionne

L'état vit dans `/volume2/docker/ha-watchdog/` :

- `echecs` — compteur d'échecs consécutifs (`0` en fonctionnement normal)
- `alerte_envoyee` — présent uniquement pendant une panne signalée

Les exécutions sont aussi journalisées via `logger -t ha-watchdog`.

## Tester le chemin d'alerte

Une exécution réussie ne prouve que la branche « tout va bien ». Pour vérifier
que l'alerte part réellement, modifier temporairement deux lignes en tête :

```sh
PORT="8121"     # port volontairement faux
SEUIL=1         # alerte dès le premier échec
```

Exécuter la tâche à la main : elle doit se terminer en **anormal (1)** et
l'e-mail doit arriver. Remettre ensuite `PORT="8123"` et `SEUIL=3`, puis
**supprimer `/volume2/docker/ha-watchdog/`** — sinon le compteur et le drapeau
d'alerte du test restent en place.

Testé le 2026-09-02 : e-mail reçu, diagnostic correct (« la machine répond au
ping mais pas Home Assistant », le Pi tournant bien à ce moment-là).

## Canal de notification

L'alerte passe par l'**e-mail du planificateur DSM**, déclenché par le code de
sortie 1. Tout ce que le script écrit sur la sortie standard forme le corps du
message.

`synodsmnotify` a été retiré : DSM refuse un titre en texte libre
(*« is neither mail string key nor i18n format »*) et l'erreur polluait le mail.
Comme l'e-mail arrive sur un compte relevé par le téléphone, la notification
push était redondante.

Pour ajouter un push dédié (ntfy, Pushover…), une ligne `curl` dans la fonction
`notifier` suffit. Elle ne dépendra pas de Home Assistant — qui est justement
hors service au moment où l'alerte part.

## Réglages

En tête du script : `HOTE`, `PORT`, `SEUIL` (nombre d'échecs avant alerte) et
`ETAT` (répertoire d'état). `SEUIL=3` avec une exécution toutes les 5 minutes
donne un délai de 15 minutes — assez pour absorber un redémarrage de Home
Assistant sans déclencher d'alerte inutile.
