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

## Réglages

En tête du script : `HOTE`, `PORT`, `SEUIL` (nombre d'échecs avant alerte) et
`ETAT` (répertoire d'état). `SEUIL=3` avec une exécution toutes les 5 minutes
donne un délai de 15 minutes — assez pour absorber un redémarrage de Home
Assistant sans déclencher d'alerte inutile.
