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
```

## Notifications

Toutes les notifications vers les téléphones passent par **un seul point d'entrée** :
`script.alerte_famille` (`scripts/alerte_famille.yaml`). Aucune automatisation n'appelle
plus `notify.mobile_app_*` directement.

Le script découvre seul les appareils de l'app Compagnon (entités `notify.*`) et n'envoie
qu'à ceux qui sont activés. L'activation se pilote depuis la vue **« Réglages »** du
tableau de bord, visible du seul compte admin.

| Élément | Rôle |
|---|---|
| `script.alerte_famille` | Point d'entrée unique, diffuse aux appareils actifs |
| `input_boolean.notif_<appareil>` | Un interrupteur par appareil, dans la vue « Réglages » |
| Vue « Réglages » | Cases à cocher + bouton de test + liste des destinataires en direct |

### Paramètres du script

| Champ | Obligatoire | Rôle |
|---|---|---|
| `message` | oui | Le texte de la notification |
| `title` | non | Titre affiché au-dessus (défaut : `Domolaunaguet`) |
| `critique` | non | Perce le mode silencieux et Ne pas déranger |
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

**Qui est en critique ?** Les quatre automatisations d'alarme : détection nuit,
détection vacances, pré-alerte silencieuse et déclenchement sonore. Rien d'autre —
la sonnette et l'alerte de porte de garage restent en notification normale.

Conséquence à connaître : la centrale `manual` n'entre en `pending` que sur un appel
à `alarm_control_panel.alarm_trigger`, lequel n'est émis que par les automatisations
nuit et vacances (l'armement, lui, passe par `arming`). Une détection réelle produit
donc **trois notifications critiques** :

| Instant | Automatisation | Message |
|---|---|---|
| t = 0 | détection nuit *ou* vacances | quel capteur a détecté |
| t = 0 | pré-alerte silencieuse | décompte entamé, lumières qui clignotent |
| t + 60 s | déclenchement sonore | sirène extérieure activée |

Les deux premières partent au même instant. C'est voulu — sur une intrusion, mieux
vaut deux alertes qu'une manquée. Pour n'en garder qu'une à t = 0, retirer
`critique: true` de `alarme-declenchement-silencieuse.yaml`.

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
