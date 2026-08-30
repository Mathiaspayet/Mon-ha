# Fichiers YAML bruts de `/config`

Copie conforme des fichiers de configuration lus sur l'instance Home Assistant,
via l'entrée **HA-MCP File & YAML Tools** (répertoires personnalisés : `knx.yaml`,
`commandline.yaml`).

| Fichier | Taille source | Modifié | Contenu |
|---|---|---|---|
| `configuration.yaml` | 3 571 o | 2026-08-06 | Point d'entrée : inclusions, 3 capteurs template, TTS, panneau d'alarme |
| `knx.yaml` | 14 487 o | 2024-11-29 | **136 entités KNX** |
| `commandline.yaml` | 246 o | 2023-06-14 | Capteur `command_line` (température CPU) |

`knx.yaml` sur l'instance utilise des fins de ligne CRLF ; la copie ici est en LF.
Le contenu est identique, sans incidence pour Home Assistant.

## Répartition de `knx.yaml`

| Domaine | Entités |
|---|---|
| `binary_sensor` | 49 |
| `light` | 31 |
| `sensor` | 30 |
| `switch` | 11 |
| `cover` | 9 |
| `climate` | 6 |

## Non versionné volontairement

- `secrets.yaml` — jamais dans un dépôt, a fortiori public (voir `.gitignore`)
- `googlecloud.json` — clé de compte de service Google Cloud, référencée par le bloc `tts:`

Ces deux fichiers sont d'ailleurs bloqués en lecture par les outils MCP eux-mêmes.
