# Fichiers YAML bruts de `/config`

Copie conforme des fichiers de configuration lus sur l'instance Home Assistant.

## Présent

- `configuration.yaml` — lu le 2026-08-30, 3 571 octets, modifié le 2026-08-06

## Encore manquant

`configuration.yaml` référence deux fichiers inclus qui ne sont **pas** lisibles par
les outils MCP : leur liste blanche couvre `configuration.yaml`, `automations.yaml`,
`scripts.yaml`, `scenes.yaml`, `secrets.yaml`, `packages/*.yaml`, `www/`, `themes/`,
`custom_templates/`, `dashboards/`, `blueprints/` — mais pas les autres fichiers
placés à la racine de `/config`.

| Fichier | Contenu | Pourquoi il compte |
|---|---|---|
| `knx.yaml` | Toute la configuration KNX | Définit thermostats, volets, chaudière, capteurs — l'essentiel du parc d'entités |
| `commandline.yaml` | Intégration `command_line` | Capteurs et commandes shell |

Pour les débloquer : ouvrir la page de réglages de l'add-on **Home Assistant MCP Server**
et ajouter `/config` aux répertoires autorisés. L'URL de cette page figure dans les
journaux de démarrage de l'add-on, sous la forme `/private_<jeton>/settings`.

Autre voie, sans réglage : les copier à la main depuis l'add-on **File editor** ou le
partage **Samba**, tous deux déjà installés.

## Non versionné volontairement

- `secrets.yaml` — jamais dans un dépôt, a fortiori public (voir `.gitignore`)
- `googlecloud.json` — clé de compte de service Google Cloud, référencée par le bloc `tts:`
