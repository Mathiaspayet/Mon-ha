# Domolaunaguet — configuration Home Assistant

Instantané versionné de l'installation Home Assistant de la maison, pris le **30 août 2026**,
avant toute modification issue de l'audit.

| | |
|---|---|
| Cœur | Home Assistant 2026.8.3 |
| Système | Home Assistant OS 18.2 · Supervisor 2026.08.0 |
| Matériel | Raspberry Pi 4 (aarch64) |
| Entités | 509 (dont 83 indisponibles) |
| Automatisations | 14 · Scripts : 4 · Zones : 20 |

## ⚠️ Dépôt public — à savoir

Ce dépôt est **public**. Deux éléments sensibles y figurent en clair, en connaissance de cause :

- **Le code de désarmement de l'alarme** (`1234`), dans `scripts/depart_maison.yaml` et
  `scripts/retour_maison.yaml`. **À changer dans Home Assistant, puis ici.**
- Le plan de la maison, les prénoms, et la liste des capteurs qui gardent chaque accès.

Les coordonnées GPS de la zone « domicile » n'ont volontairement pas été exportées.
Aucun mot de passe de caméra, jeton d'API ou contenu de `secrets.yaml` ne figure dans ce dépôt.

## Contenu

```
automations/     14 automatisations, une par fichier
scripts/          4 scripts
dashboards/       tableau de bord « Domolaunaguet » (9 vues) + ressources Lovelace
helpers/          input_boolean, input_number, groupes et moyennes
registry/         zones, personnes
integrations/     dépôts HACS (avec versions), Apps, entrées de configuration
blueprints/       métadonnées du blueprint utilisé
docs/             rapport d'audit du 29 août 2026
```

## Ce qui n'est pas ici

L'export passe par l'API Home Assistant. Les outils fichiers du serveur MCP exigent l'entrée
**« HA-MCP File & YAML Tools »**, non installée sur l'instance — ces éléments ne sont donc pas
récupérables pour l'instant :

- `configuration.yaml` et les fichiers `packages/*.yaml` — dont **toute la configuration KNX**
  (adresses de groupe, thermostats, volets, chaudière). C'est le manque le plus important.
- Les capteurs `template:` définis en YAML
- `custom_components/`, `themes/`, `www/`
- `secrets.yaml` (jamais à versionner, voir `.gitignore`)

**Pour compléter l'export** : dans Home Assistant, Paramètres → Appareils et services →
*HA-MCP Custom Component* → « Ajouter une entrée » → **HA-MCP File & YAML Tools**.
Les fichiers bruts deviennent alors lisibles et pourront être ajoutés ici.

Trois éléments restent partiels côté API : les helpers de type *flow* (groupes, moyennes) sont
reconstitués depuis les attributs des entités plutôt que depuis leur configuration ; le corps du
blueprint n'est pas exposé (seules ses métadonnées et son `source_url` le sont) ; la scène
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

## Audit

`docs/audit-2026-08-29.html` — revue complète : 4 constats critiques, 6 de fiabilité,
9 d'hygiène, 9 pistes d'amélioration et un plan d'action en 3 phases.

Les correctifs n'ont **pas** encore été appliqués : le contenu de ce dépôt reflète l'état
du système *avant* intervention.
