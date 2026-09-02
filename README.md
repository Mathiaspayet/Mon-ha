# Domolaunaguet — configuration Home Assistant

Instantané versionné de l'installation Home Assistant de la maison, pris le **30 août 2026**,
avant toute modification issue de l'audit.

| | |
|---|---|
| Cœur | Home Assistant 2026.8.3 |
| Système | Home Assistant OS 18.2 · Supervisor 2026.08.0 |
| Matériel | Raspberry Pi 4 (aarch64) |
| Entités | 509 (dont 83 indisponibles) |
| Automatisations | 14 · Scripts : 5 · Zones : 20 |

## ⚠️ Dépôt public — à savoir

Ce dépôt est **public**. Deux éléments sensibles y figurent en clair, en connaissance de cause :

- **Le code de désarmement de l'alarme** (`1234`), dans trois fichiers :
  `config/configuration.yaml` (bloc `alarm_control_panel`, la source),
  `scripts/depart_maison.yaml` et `scripts/retour_maison.yaml`.
  **À changer dans Home Assistant, puis ici.**
- Le plan de la maison, les prénoms, et la liste des capteurs qui gardent chaque accès.
- L'identifiant interne du compte admin (`visible:` de la vue « Réglages », dans
  `dashboards/lovelace.yaml`). C'est un UUID opaque, il ne permet aucune connexion.

Les coordonnées GPS de la zone « domicile » n'ont volontairement pas été exportées.
Aucun mot de passe de caméra, jeton d'API ou contenu de `secrets.yaml` ne figure dans ce dépôt.

## Contenu

```
config/          fichiers YAML bruts : configuration.yaml, knx.yaml, commandline.yaml
automations/     14 automatisations, une par fichier
scripts/          5 scripts (dont alerte_famille, point d'entrée des notifications)
dashboards/       tableau de bord « Domolaunaguet » (10 vues) + ressources Lovelace
helpers/          input_boolean, input_number, groupes et moyennes
registry/         zones, personnes
integrations/     dépôts HACS (avec versions), Apps, entrées de configuration
blueprints/       métadonnées du blueprint utilisé
docs/             rapport d'audit du 29 août 2026
nas/              script de surveillance du Pi depuis le NAS Synology
```

## Nettoyage KNX du 2 septembre 2026

Le recoupement avec le projet ETS « Hangar » a permis de faire le tri entre erreurs
d'adressage, objets jamais raccordés et pannes réelles. Deux chantiers en ont découlé.

### 34 entités fantômes supprimées

Des entrées du registre héritées de configurations successives, sans aucune
configuration derrière, `unavailable` en permanence. Aucune n'était référencée.
Les entités indisponibles passent de **80 à 46** — et il n'en reste **plus une seule
côté KNX**.

Point vérifié avant suppression : les fonctions correspondantes tournaient toutes
sous d'autres identifiants. Un fantôme avait **un** enregistrement en 72 h
(`unavailable`, jamais changé) quand l'entité active en avait plus de deux cents.

### 8 entités mortes hors KNX

Distinction importante, faite avec `dead_entities` : **`config_entry_orphans` = 0**.
Aucune entité de Daikin, Reolink, Cast, app mobile ou Samba n'est réellement orpheline
— leurs intégrations tournent, ces entités sont seulement non renseignées ou hors
ligne. Les supprimer serait sans effet : Home Assistant les recrée au rechargement.

Seules 8 n'avaient plus aucune intégration derrière (`config_entry_id: null`) :

- Les 7 capteurs **System Monitor** — `processor_temperature`, `memory_use_percent`,
  `disk_use_percent_config`, `load_1m`, `swap_use_percent`, `processor_use_percent`,
  `last_boot`. L'intégration n'est plus configurée nulle part.
- `media_player.deurbel` (WebRTC).

⚠️ Conséquence : **il n'y a plus de supervision système de l'hôte.** Seul
`sensor.cpu_temperature`, via `command_line`, subsiste. Vu le problème de SSD USB,
réactiver System Monitor (désormais une intégration à ajouter depuis l'interface)
redonnerait la surveillance de l'espace disque et de la charge.

### 13 entités renommées

Les identifiants avaient dérivé de ce que les entités mesurent réellement. Les plus
trompeurs :

| Ancien identifiant | Ce que l'entité mesure | Nouvel identifiant |
|---|---|---|
| `sensor.pression_eau_chaudiere` | Température extérieure | `sensor.temperature_exterieure_chaudiere` |
| `binary_sensor.erreur_generale_chaudiere` | État H1 | `binary_sensor.etat_h1` |
| `binary_sensor.etat_chaffage_h1` | Vanne chambre Margaux | `binary_sensor.etat_vannne_chambre_margaux` |
| `binary_sensor.etat_chauffage_h2` | Blocage circulateur étage | `binary_sensor.blocage_circulateur_radiateur_etage` |
| `switch.marche_arret_ecs` | Switch H1 | `switch.switch_h1` |
| `switch.marche_arret_h1` | Pompe de bouclage ECS | `switch.switch_pompe_bouclage_ecs` |
| `sensor.temperature_interrupteur` | Température chambre Parents | `sensor.temperature_chambre_parents` |
| `sensor.temperature_salle_d_eau_2` | Température Salon Télé | `sensor.temperature_salon_tele` |

Les suffixes `_2` que les fantômes imposaient aux entités actives ont été récupérés
(`etat_flamme_chaudiere`, `forcage_chauffage_salle_d_eau`, `pression_eau_chaudiere`).

**17 références mises à jour** : 11 cartes du tableau de bord, 4 dans deux
automatisations, 2 dans les helpers min/max. Ces derniers sont le point aveugle
classique — un renommage d'entité ne les met **jamais** à jour, et la moyenne
extérieure s'est retrouvée à moyenner une pression en pascals avec des températures
le temps de la correction.

Un consommateur avait été oublié au premier passage : le capteur template
`Pression Chaudiere en Bar`, dans `configuration.yaml`, qui lisait
`sensor.pression_eau_chaudiere_2`. Il est resté `unavailable` quelques minutes avant
d'être corrigé et rechargé.

## Notifications

Toutes les notifications vers les téléphones passent par **un seul point d'entrée** :
`script.alerte_famille` (`scripts/alerte_famille.yaml`). Aucune automatisation n'appelle
plus `notify.mobile_app_*` directement.

Le script découvre seul les appareils de l'app Compagnon (entités `notify.*`) et n'envoie
qu'à ceux qui sont activés. L'activation se pilote depuis la vue **« Réglages »** du
tableau de bord, visible du seul compte admin.

| Élément | Rôle |
|---|---|
| `script.alerte_famille` | Point d'entrée unique, diffuse à tous les appareils ciblés |
| `input_boolean.critique_<alerte>` | Un interrupteur par **type d'alerte** : critique ou non |
| Vue « Réglages » | Liste des appareils (lecture seule) + interrupteurs de criticité + tests |

### Destinataires

Aucune configuration. Tout appareil de l'app Compagnon est notifié dès qu'il
apparaît — le script les découvre via `integration_entities('mobile_app')`.

Pour en **exclure** un, l'ajouter à la liste `exclus` en tête de la séquence de
`scripts/alerte_famille.yaml`. Aujourd'hui : `['notify.i10_pro']` (tablette murale).

⚠️ Cette liste est **dupliquée** dans la carte « Appareils » de la vue « Réglages »
(`dashboards/lovelace.yaml`), qui s'en sert pour l'affichage. Modifier les deux.

### Paramètres du script

| Champ | Obligatoire | Rôle |
|---|---|---|
| `message` | oui | Le texte de la notification |
| `title` | non | Titre affiché au-dessus (défaut : `Domolaunaguet`) |
| `alerte` | non | Id du type d'alerte — le script lit `input_boolean.critique_<id>` |
| `critique` | non | Force la criticité, l'emporte sur l'interrupteur (boutons de test) |
| `donnees` | non | Bloc `data` supplémentaire fusionné au payload |

### Les trois chemins

Le script choisit sa route selon les paramètres reçus :

1. **Aucun appareil actif** → `persistent_notification`, l'alerte n'est jamais perdue.
2. **`critique` ou `donnees` fourni** → services hérités `notify.mobile_app_<appareil>`,
   un appel par appareil, avec un bloc `data` adapté à la plateforme :
   - **iOS** : `push.sound.critical = 1`, volume 1.0 — alerte critique.
   - **Android** : `channel: alarm_stream`, `ttl: 0`, `priority: high`, `sticky` —
     passe par le flux alarme, ignore le silencieux et Ne pas déranger.
   La plateforme est déduite de `device_attr(entité, 'manufacturer')`.
3. **Par défaut** → `notify.send_message` sur la liste d'entités, un seul appel.
   C'est le chemin natif et robuste ; il ne transporte que `message` et `title`,
   ce qui est précisément pourquoi le chemin 2 existe.

**Qui est en critique ?** Ça ne se décide plus dans le YAML : chaque automatisation
déclare son type d'alerte, et l'interrupteur correspondant se règle depuis la vue
« Réglages ».

| Id d'alerte | Automatisation | Réglage initial |
|---|---|---|
| `alarme_declenchee` | Déclenchement sonore et visuel | 🔴 critique |
| `alarme_nuit` | Détection nuit | 🔴 critique |
| `alarme_vacances` | Détection vacances | 🔴 critique |
| `alarme_prealerte` | Pré-alerte silencieuse | 🔴 critique |
| `sonnette` | Sonnette | normal |
| `garage` | Porte de garage restée ouverte | normal |

Conséquence à connaître : la centrale `manual` n'entre en `pending` que sur un appel
à `alarm_control_panel.alarm_trigger`, lequel n'est émis que par les automatisations
nuit et vacances (l'armement, lui, passe par `arming`). Avec les quatre alarmes en
critique, une détection réelle produit **trois notifications critiques** — la détection
et la pré-alerte au même instant, le déclenchement sonore 60 s plus tard. Pour n'en
garder qu'une à t = 0, décocher « Pré-alerte » dans la vue « Réglages ».

⚠️ **Sur iOS**, l'alerte critique exige que « Alertes critiques » soit autorisé dans
l'app Compagnon (Réglages → Notifications). Sans cette permission, la notification
arrive quand même, mais en mode normal.

⚠️ **Ne pas renommer les entités `notify.*`** : le chemin 2 déduit le nom du service
hérité du slug de l'entité (`notify.pixel_9a` → `notify.mobile_app_pixel_9a`).

**Ajouter un téléphone** : rien à faire, il est notifié dès qu'il apparaît dans l'app
Compagnon. Pour lui donner un interrupteur, créer le helper `Notif <nom de l'appareil>`
— le nom doit produire `input_boolean.notif_<slug de l'entité notify>`.

**Retirer un téléphone** : décocher sa case dans « Réglages ».

Le script porte `continue_on_error` sur l'envoi : un appareil injoignable n'interrompt
plus la suite de l'automatisation appelante — c'était la cause du silence complet des
alertes avant le 2 septembre 2026.

## Stockage et écritures disque

Le Pi démarre sur un SSD USB via un pont Realtek RTL9210, dont le pilote UAS
déclenche des resets sous charge d'écriture soutenue. Correctif définitif :
`usb-storage.quirks=0bda:9210:u` en tête de `cmdline.txt` sur la partition de
démarrage — **nécessite un accès physique au support**, non appliqué à ce jour.

En attendant, les écritures sont réduites. Réglages appliqués le 2026-09-02
(ils vivent dans `.storage`, pas dans ce dépôt) :

| Réglage | Avant | Après | Pourquoi |
|---|---|---|---|
| `automation.reboot_ha_host` | actif (mercredi 03h00) | **désactivé** | Le reset UAS du 2026-09-02 03h08 est survenu 8 min après ce redémarrage |

Sauvegarde inchangée sur décision explicite : quotidienne **avec la base**, vers le
NAS Synology, 20 copies, dossier `share` inclus.

### Chiffrement des sauvegardes — décision : non (C5, clos)

Les sauvegardes ne sont **pas chiffrées** (`protected: false` sur l'agent), et
c'est délibéré. Une clé figure bien dans la configuration mais reste inactive ;
elle ne doit **jamais** être copiée dans ce dépôt public.

Raison : le 1ᵉʳ septembre 2026, la récupération après la panne du Pi s'est faite
en décompressant l'archive **à la main dans File Station**. Une archive chiffrée
aurait rendu ce chemin impossible — il aurait fallu la clé au moment précis où
Home Assistant était injoignable. Le chiffrement aurait bloqué la seule
récupération qui a effectivement fonctionné.

Contrepartie assumée : l'archive contient `secrets.yaml`, les jetons d'API, les
identifiants des caméras et le code d'alarme. **Leur confidentialité vaut donc
celle du NAS** — un partage ouvert trop largement les exposerait en clair.

### Bloc `recorder:` — écrit, en attente de redémarrage

Il n'existait aucun bloc `recorder:` : Home Assistant tournait donc sur les valeurs
par défaut. Ajouté à `config/configuration.yaml` le 2026-09-02, validé par
`check_config`, **effectif au prochain redémarrage** :

| Réglage | Défaut | Retenu | Effet |
|---|---|---|---|
| `commit_interval` | 1 s | **30 s** | ~30× moins d'opérations d'écriture |
| `auto_repack` | `true` | **`false`** | Supprime la réécriture complète de la base, mensuelle |
| `purge_keep_days` | 10 | **30** | Historique détaillé triplé |
| `exclude.domains` | — | `update` | Bruit sans valeur historique |

⚠️ `purge_keep_days: 30` triple la taille de la base, et la base est incluse dans la
sauvegarde quotidienne : celle-ci va grossir en proportion (~175 Mo aujourd'hui).
Si l'écriture quotidienne redevient un problème, c'est le premier réglage à revoir.

Note : les capteurs numériques portant un `state_class` (températures, énergie)
alimentent les **statistiques long terme**, qui ne sont jamais purgées.
`purge_keep_days` ne joue que sur l'historique détaillé — les courbes de température
horaires sont déjà conservées indéfiniment.

### Reste à appliquer

- Nettoyage des `sync_state` KNX sur les adresses de groupe qui ne répondent pas
  (991 avertissements `xknx` en 21 h). Nécessite aussi un redémarrage.

## Couverture

L'export est complet pour tout ce que Home Assistant expose. Les fichiers YAML bruts
sont dans `config/` : `configuration.yaml`, `knx.yaml` (136 entités KNX) et
`commandline.yaml`.

Non versionnés volontairement : `secrets.yaml` et `googlecloud.json` (clé de service) —
tous deux également bloqués en lecture par les outils MCP.

Trois éléments restent partiels côté API : les helpers de type *flow* (groupes, moyennes) sont
reconstitués depuis les attributs des entités plutôt que depuis leur configuration ; le corps du
blueprint n'est pas exposé (seuls ses métadonnées et son `source_url` le sont) ; la scène
`switch_presence_simulation_scene` est générée automatiquement par l'intégration Presence
Simulation et n'a pas été exportée.

## Restauration

Ce dépôt est une **référence de configuration**, pas une sauvegarde binaire restaurable d'un bloc.
Pour un retour arrière complet, utiliser les sauvegardes Home Assistant (agent Synology).

Ordre à respecter pour reconstruire depuis zéro :

1. Installer les 9 dépôts **HACS** listés dans `integrations/hacs.yaml`, aux versions indiquées
2. Recréer les **helpers** (`helpers/`) — les automatisations en dépendent
3. Recréer les **zones** (`registry/areas.yaml`) et les personnes
4. Importer le **blueprint** depuis son `source_url`
5. Importer **scripts** puis **automatisations** (les automatisations appellent les scripts)
6. Déclarer les **ressources Lovelace**, puis importer le tableau de bord

## Diagnostics

| Document | Date | Contenu |
|---|---|---|
| `docs/diagnostic-2026-08-30.html` | 30 août | **À jour.** Refait avec `knx.yaml` en main : 5 critiques, 8 fiabilité, 9 hygiène, 3 corrections au précédent |
| `docs/audit-2026-08-29.html` | 29 août | Premier passage, conservé pour l'historique. Trois de ses conclusions sont corrigées par le suivant |
| `docs/procedure-ha-sur-nas.html` | 31 août | Mode opératoire de secours : remonter HA sur le Synology DS218+ depuis la sauvegarde. **Validé sur le terrain** — KNX opérationnel |
| `docs/procedure-compagnon-tailscale.html` | 31 août | Connecter l'app Compagnon à l'instance du NAS via Tailscale |
| `docs/procedure-autopsie-pi.html` | 31 août | Que vérifier dans les journaux au redémarrage du Pi pour identifier la cause de la panne |

Les correctifs n'ont **pas** encore été appliqués : ce dépôt reflète l'état du système
*avant* intervention. C'est le point de départ.
