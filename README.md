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

Premier tri avec `dead_entities` : **`config_entry_orphans` = 0**. Ce compteur ne dit
qu'une seule chose — aucune intégration n'a disparu en laissant ses entités derrière
elle. Il ne dit **rien** des entités qu'une intégration toujours chargée a cessé de
fournir : c'est le second panier, `stale_restored`, dépouillé plus bas.

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

## Résidus d'anciennes versions — Reolink et Daikin

Question posée après le nettoyage KNX : reste-t-il des entités qui servaient à une
installation ou à une **version antérieure** ? `config_entry_orphans` ne répond pas à
ça. Le bon panier est `stale_restored` : l'entité est restaurée depuis le registre au
démarrage, mais l'intégration chargée ne la fournit plus. 33 entités s'y trouvaient.

### Reolink — rien à supprimer

Deux appareils, deux entrées de configuration, et c'est tout :

| Entrée | MAC | Matériel | Entités |
|---|---|---|---|
| Interphone | `ec:71:db:87:b3:e1` | Reolink Video Doorbell PoE | 50 |
| Entree garage | `ec:71:db:3c:58:d3` | RLC-810A | 44 |

Aucun appareil orphelin, aucune entité d'une caméra disparue. Les deux entrées
`reolink` supplémentaires — « entree (192.168.0.31) » et « camera1 (192.168.0.30) » —
sont en `source: ignore` / `not_loaded` : des **découvertes réseau écartées**, sans
appareil ni entité derrière. Leurs adresses MAC diffèrent des deux caméras en service,
donc elles désignent bien d'autres matériels vus sur le réseau. Elles ne coûtent rien.

Quatre entités Reolink sont `stale_restored` mais **conservées volontairement** : ce
sont des capacités que le matériel n'expose pas *aujourd'hui*, et elles reviendraient
si la configuration de la caméra changeait.

- `binary_sensor.entree_garage_intrusion_area_1_vehicle` et `…_animal` — la zone
  d'intrusion 1 du RLC-810A n'est armée que sur la détection de personne.
- `number.interphone_speak_volume` et `number.interphone_volume_de_la_sonnette` — non
  exposées par le micrologiciel `v3.0.0.6460` de l'interphone.

### Daikin — 28 entités supprimées

Là, oui. L'intégration HACS `daikin_onecta` a renommé et retiré des entités au fil de
ses versions ; les anciennes sont restées dans le registre, `unavailable` en
permanence, sur les deux unités (clim chambre, clim couloir étage) :

| Famille | Par unité | Ce qui les remplace |
|---|---|---|
| `ratelimit_{minute,day,remaining_minutes,retry_after,ratelimit_reset}` | 5 | `sensor.…_ratelimit_remaining_day` sur le sous-appareil Gateway |
| `gateway_{firmware_version,model_info,serial_number}`, `indoorunit_software_version` | 4 | Attributs du registre d'appareils (`sw_version`, modèle) |
| `climatecontrol_{name,on_off_mode,powerful_mode}` | 3 | L'entité `climate` et `binary_sensor.…_is_powerful_mode_active` |
| `gateway_mac_address` | 1 | Plus renvoyé par l'API Onecta |
| `update.…_gateway_firmware_update` | 1 | Son jumeau vivant, jusqu'ici suffixé `_2` |

**La preuve est nette sur la dernière ligne** : le même appareil portait deux entrées
de registre, `…_firmware_update` (ancien `unique_id`, `unavailable`) et
`…_gateway_firmware_update` (nouveau, `off`). La seconde avait dû prendre un suffixe
`_2` parce que l'identifiant était occupé par le fantôme. Les deux fantômes supprimés,
les suffixes `_2` ont été récupérés.

Aucune des 28 n'était référencée : ni dans les automatisations, scripts, scènes et
helpers, ni dans le tableau de bord, ni dans les YAML du dépôt. Seule
`sensor.clim_chambre_climatecontrol_outdoor_temperature` est consommée (moyenne de
température extérieure) — elle est vivante et n'a pas bougé.

Les entités indisponibles passent de **38 à 10**.

### Les 10 restantes ne sont pas des résidus

| Entité(s) | Pourquoi |
|---|---|
| 4 entités Reolink | Capacités matérielles non exposées (voir ci-dessus) |
| `media_player.shield` | Cast joignable jusqu'au 25/08 à 23 h 04, hors ligne depuis. Appareil éteint, pas un fantôme |
| `sensor.samba_share_cpu_percent`, `…_memory_percent` | L'add-on **Samba share est installé mais arrêté**. Reviennent à son démarrage |
| `sensor.iphone_marine_{camera_stream,kiosk_brightness,kiosk_volume}` | Capteurs de l'app Compagnon non activés sur le téléphone |

## Phase 2 KNX — ce qui est dans ETS et pas dans Home Assistant

Le recoupement du projet ETS avec `knx.yaml` donne **468 adresses de groupe** : 232 déjà
exploitées, 153 sans le moindre objet de communication raccordé, et **83 qui ont un objet
réel sur un appareil programmé** sans exister dans Home Assistant. Ces 83 se rangent en
neuf familles.

Deux constats préalables : le groupe 17 « Chaudiere » est **déjà mappé à 100 %** (17
adresses sur 17), et les prises commandées n'ont plus rien à donner (`Defaut charge` et
`fonction long` n'ont aucun objet derrière).

| # | Famille | Adresses | Décision |
|---|---|---:|---|
| 1 | Éclairages groupés (groupe 15) | 19 | **Laissé.** Stratégie KNX pour commander plusieurs actionneurs d'un seul télégramme, pas une remontée d'information |
| 2 | Thermostat salon télé (groupe 14) | 9 | **Laissé.** Ce thermostat ne pilote aucun radiateur |
| 3 | Diagnostic rubans LED | 17 | **Fait** |
| 4 | Consigne absolue et modes 1 bit des thermostats | 8 | **Laissé.** Le `setpoint_shift` et le `mode selection` en place suffisent |
| 5 | Horloge du bus | 3 | **Fait**, en lecture |
| 6 | HCL des rubans | — | **Fait** |
| 7 | Diagnostic volets (`sens`, `Diagnostique`) | 16 | **Laissé** |
| 8 | Variation relative (DPT 3.007) | 4 | **Laissé.** Télégramme d'appui long ; HA envoie des valeurs absolues |
| 9 | Écran et objets système du bus | 7 | **Fait**, en écoute seule, dans la vue « Diag » |

### Quatre capteurs qui écoutaient une plage morte

`Valeur Cuorant dépassée`, `Température élevée`, `Etat alimentation 24V` et
`Etat Jour=1/nuit=0` pointaient sur `1/2/9` à `1/2/12`. Ce sous-groupe n'a **aucun objet
de communication raccordé** côté ETS. Confirmé par l'historique : sur dix jours, ces
quatre entités n'ont changé d'état qu'aux redémarrages de Home Assistant. Zéro télégramme.

Les vraies adresses, par ruban :

| | Salon piano (1.1.15) | Double hauteur (1.1.37) |
|---|---|---|
| Erreur courant | `6/3/9` | `6/4/9` |
| Surchauffe | `6/3/11` | `6/4/11` |
| Alimentation 24 V | `6/3/12` | `6/4/12` |
| Couleur en Kelvin | `6/3/8` | `6/4/8` |

Le canal « salon » (`6/2`) n'expose pas ce diagnostic : sur cet actionneur il est porté
par le canal double hauteur. L'objet `Day/Night` réel est en `12/3/0`, raccordé aux six
thermostats et au variateur.

Après rechargement, les six capteurs portent tous l'attribut `source: 1.1.15` ou
`1.1.37` — preuve qu'ils reçoivent réellement du bus. Les deux capteurs Kelvin donnent
2700 K et 3191 K.

### ⚠️ L'identifiant d'une entité KNX dérive de son adresse, pas de son nom

Changer `state_address` en gardant le même `name` ne déplace pas l'entité : Home Assistant
en crée une nouvelle (suffixée `_2`) et laisse l'ancienne orpheline dans le registre. Les
quatre orphelines ont été retirées à la main et `binary_sensor.etat_jour_1_nuit_0` a
récupéré son identifiant.

### L'horloge du bus fonctionne

Question ouverte avant de la remonter : qui émet l'heure ? Réponse immédiate —
`datetime.bus_horodatage` affiche l'heure exacte à la seconde. Le serveur de temps
configuré dans l'alimentation KNX publie bien sur `0/0/4`, `0/0/5` et `0/0/6`.

Les trois entités sont en lecture. Elles ont techniquement une adresse d'écriture — la
plateforme KNX l'exige — donc **ne pas les modifier à la main** : Home Assistant écrirait
l'heure sur le bus en concurrence avec l'alimentation.

### Vue « Diag »

Tout ce qui vient d'être ajouté est regroupé dans une vue `diag` du tableau de bord,
visible du seul compte admin, à trier plus tard. Les deux commandes à risque — `0/0/3`
(ordre de reset du bus) et `12/6/0` (étalonnage du temps de déplacement des volets) — y
sont en **écoute seule** : aucun bouton ne peut les déclencher.

Restent à confirmer sur le terrain :

- Le sens de `binary_sensor.etat_jour_1_nuit_0` — `off` en pleine journée, à vérifier à la
  tombée de la nuit.
- Le sens des capteurs `Alimentation 24 V`, à `off` alors que les trois rubans sont
  éteints. Allumer un ruban tranchera ; si le sens est inversé, ajouter `invert: true`.
- Les deux `switch` HCL : la commande DPT 1.010 n'a jamais été essayée depuis Home
  Assistant.

### Réserve sur le fichier ETS

Le `.knxproj` date du 18/08/2024. Sur des thermostats qui *fonctionnent* aujourd'hui,
certains objets d'état y apparaissent comme non raccordés : le fichier sous-déclare. Il
sert à dire « cette adresse existe », jamais « cette adresse est morte ».

## Refonte de l'interface — étape 1 : le registre

Le cahier des charges de la refonte a établi que les fonctions modernes de Home Assistant
— page d'accueil mobile, cartes de zone, navigation par pièce — reposent toutes sur le
registre des zones et des étages, et que ce registre était incomplet. Cette étape le
remet d'aplomb. **Aucun effet visible**, mais rien du reste n'est possible sans.

### Trois étages, vingt-et-une zones

| Étage | Niveau | Zones |
|---|---:|---|
| Rez-de-chaussée | 0 | Buanderie, Bureau, Cellier, Cuisine, Entrée, Salle à manger, Salon, Salon Piano, Salon Télé, WC RDC, **Garage** |
| Étage | 1 | Chambre Auguste, Chambre d'amis, Chambre Margaux, Chambre parentale, Couloir Étage, Salle d'eau, Salle de bain, WC étage, **Patio** |
| Extérieur | 2 | Extérieur |

La répartition vient des sections « Rez de Chaussée » et « Etage » de la vue Éclairage
existante, et des groupes `Volets étage` / `Volets Rez de Chaussée`. La salle d'eau et la
salle de bain sont donc bien à l'étage.

Deux zones créées, une supprimée :

- **Garage** (rez-de-chaussée). L'éclairage du garage, la porte, son blocage et le
  capteur d'alarme n'avaient aucune zone alors que la vue Éclairage les range au
  rez-de-chaussée.
- **Patio**, rattaché à l'**étage** et non à l'extérieur : le patio est à ce niveau.
  C'est aussi ce que faisait la vue Éclairage, qui listait `light.patio_exterieur` sous
  « Etage » — ce qui avait été pris pour une commodité d'affichage était juste.
- **Cabanon** supprimé : il n'existe pas.

### L'éclairage du jardin et le projet ETS

Trois lumières restent à l'extérieur après le déplacement du patio : la **terrasse**,
**Porsche et travées**, et l'**éclairage du jardin**. Ce dernier sert peu — il n'a pas
été allumé une seule fois sur dix jours d'historique — ce qui ne l'empêche pas d'exister
et d'être bien dehors.

À noter pour plus tard : son adresse `18/0/0` n'est pas dans le projet ETS, dont les
groupes principaux s'arrêtent à 17. L'export `.knxproj` datant du 18/08/2024, cet
éclairage lui est vraisemblablement postérieur. Un rappel de plus que ce fichier sert à
dire « cette adresse existe », jamais « cette adresse est morte ».

### Douze entités rattachées

- **4 lumières** : `eclairage_garage` → Garage, `eclairage_jardin` → Extérieur,
  `ruban_led_salon` → Salon, `ruban_led_salon_piano` → Salon Piano.
- **6 thermostats KNX** : Chambre parentale, Chambre Auguste, Chambre Margaux,
  Chambre d'amis, Salle de bain (Salle d'eau était déjà rattachée).
- **2 clim Daikin** : « clim chambre » dans la Chambre parentale, où elle complète le
  thermostat KNX, et « Clim couloir étage » dans le Couloir Étage.
- **1 lumière déplacée** : `patio_exterieur` de Extérieur vers Patio.

Les 8 thermostats sont désormais rattachés, contre 1 au départ.

### ⚠️ Ce qui n'a pas pu être fait par l'API

Le champ `temperature_entity_id` de chaque zone reste vide. Le serveur MCP refuse
`config/area_registry/update` (« mutates persistent state that a dedicated tool guards »)
et l'outil dédié `ha_set_area_or_floor` n'expose pas ce champ.

**À faire à la main** dans Paramètres → Zones et étiquettes → la zone → *Capteur de
température*. Neuf zones sont concernées, la correspondance est dans
`registry/areas.yaml` sous la clé `temperature_entity_id_souhaite` :

| Zone | Capteur |
|---|---|
| Chambre Auguste | `sensor.temperature_chambre_auguste` |
| Chambre d'amis | `sensor.temperature_chambre_amis` |
| Chambre Margaux | `sensor.temperature_chambre_margaux` |
| Chambre parentale | `sensor.temperature_chambre_parents` |
| Salle d'eau | `sensor.temperature_salle_d_eau` |
| Salle de bain | `sensor.temperature_salle_de_bain` |
| Salon Télé | `sensor.temperature_salon_tele` |
| Couloir Étage | `sensor.clim_couloir_etage_climatecontrol_room_temperature` |
| Extérieur | `sensor.temperature_exterieure_meteo_france` |

Sans ce champ, la carte de zone n'affiche pas la température toute seule et il faut la
nommer explicitement dans chaque carte. Ça marche, c'est juste moins propre à maintenir.

### Décisions arrêtées pour la suite

| Sujet | Décision |
|---|---|
| Thème | Sombre sur la tablette murale, thème du système sur les téléphones |
| Accès | Maison, Pièces, Confort, Sécurité pour tous ; Technique réservée au compte admin |
| Bloc « attention » | Sécurité, oublis du quotidien, pannes techniques. **Pas** les alertes système, qui vont dans Technique |
| Vue Diag | Reste dans l'ancien tableau de bord jusqu'au tri des objets KNX, puis ce qui survit rejoint Technique |

## Refonte — étape 2 : la vue Maison

Nouveau tableau de bord **`maison-v2`**, titre « Maison », visible de tous. Le tableau
historique `lovelace` n'est pas touché et reste celui par défaut. Config versionnée dans
`dashboards/maison.yaml`.

Une seule vue pour l'instant. Vue de type `sections`, natif Home Assistant, **aucune
ressource HACS**.

### Ce qu'il y a dessus

**Bandeau** (badges de vue) — Marine, Mathias, alarme, température intérieure, dehors.

**Attention** — conditionnée par un OU sur **18 déclencheurs**. La section n'apparaît pas
du tout quand tout va bien, et chaque carte porte en plus sa propre condition : seule la
ligne concernée s'affiche.

| Famille | Déclencheurs |
|---|---|
| Sécurité | Alarme `triggered` / `pending` / `arming` ; les 11 ouvrants Tydom |
| Oublis | Porte de garage ouverte |
| Panne technique | Pression chaudière sous 1 bar ; erreur courant et surchauffe des deux rubans LED |

Les alertes système (sauvegarde, NAS, Pi) sont volontairement absentes — elles iront dans
la vue Technique.

**Raccourcis** — Départ (avec confirmation), Retour, Lumières, Volets.

**Allumé en ce moment** — section masquée si rien n'est allumé, sinon la liste des
lumières allumées, chacune extinguible d'un geste.

**La maison** — six cartes de zone : Salon, Salon Télé, Cuisine, Chambre parentale,
Garage, Extérieur. Le reste des pièces ira dans la vue Pièces.

### Deux points de méthode

**Le vocabulaire Tydom est `LOCKED` / `UNLOCKED`**, plus `unknown` à chaque redémarrage.
Les conditions filtrent sur `UNLOCKED` et `OPENED` — une correspondance **positive** —
pour qu'un `unknown` transitoire ne déclenche pas de fausse alerte au démarrage.

**Deux cartes `entity-filter` remplacent une quarantaine de cartes conditionnelles.**
Elles n'affichent que les entités correspondant à leur condition et se masquent
entièrement quand aucune ne correspond. Une pour les ouvrants, une pour les lumières
allumées.

### Ce qui n'a pas pu être vérifié

Le moteur de capture d'écran (app Puppet) n'est pas installé : la vue n'a pas pu être
regardée avant livraison. Le rendu est à valider sur téléphone.

Les capteurs `alimentation 24V` des rubans LED sont **volontairement exclus** du bloc
Attention : leur polarité n'est pas confirmée (voir phase 2 KNX), les intégrer
maintenant risquerait une alerte permanente à tort.

### Corrections après la première capture d'écran

Trois défauts relevés sur le rendu réel, tous corrigés.

**Les badges n'affichaient pas les noms.** `show_state: true` sans `show_name: true` ne
montre que l'état : les puces de personne affichaient « Maison » et « Absent » sans dire
de qui il s'agissait, et la première ressemblait au titre de la page. Les cinq badges
portent désormais les deux options, plus une icône explicite pour les températures.

**Les cartes de zone affichaient un carré hachuré.** Une zone sans `icon` fait afficher à
la carte `area` un cadre « image manquante ». Les **21 zones** ont maintenant leur icône —
un investissement qui resservira pour la vue Pièces.

**La tuile Lumières portait un interrupteur pleine largeur** que le `feature: toggle`
ajoute sur un groupe. Retiré : la tuile bascule déjà au toucher, et l'écart de traitement
avec les flèches des Volets était injustifié.

### Une bonne surprise

La carte `area` **trouve seule la température de la pièce** en agrégeant les entités de
la zone : Salon Télé affiche 27,3 °C et Chambre parentale 26 °C alors que le champ
`temperature_entity_id` n'a pas pu être écrit. Le renseigner à la main reste utile pour
choisir explicitement quel capteur fait foi quand une pièce en compte plusieurs, mais ce
n'est plus bloquant.

## Refonte — étape 3 : la vue Pièces

Les **21 zones rangées par étage** : Rez-de-chaussée (11), Étage (9), Extérieur (1).
Chaque carte affiche la température de la pièce et porte une commande `area-controls`
pour allumer ou éteindre ses lumières sans quitter la vue.

### ⚠️ Le piège du `tap_action` de la carte de zone

J'avais d'abord écarté les sous-vues en affirmant que la carte de zone ouvrait « la page
de zone native de Home Assistant ». **C'était faux.** La documentation est formelle : le
`tap_action` de la carte `area` vaut **`none` par défaut**, et il n'existe aucune page de
zone native vers laquelle naviguer. Appuyer sur une carte ne faisait strictement rien.

Les 21 sous-vues prévues au cahier des charges sont donc bien nécessaires, et l'argument
de maintenance avancé pour les éviter ne tenait pas.

Chaque carte de zone porte maintenant un `tap_action` explicite vers sa sous-vue.

### Correction de mise en page sur Maison

La tuile Lumières faisait une ligne quand Volets en faisait deux — ses flèches
haut/stop/bas prennent une rangée supplémentaire — ce qui laissait un trou sous
Lumières. Les deux tuiles sont fixées à `rows: 2`.

L'icône de la Cuisine passe de `mdi:countertop` à `mdi:silverware-fork-knife` : la
première ne se lit pas à la taille d'une carte de zone.

### Les 21 sous-vues

Une par pièce, en `subview: true` — elles n'encombrent donc pas la barre d'onglets — avec
un `back_path` vers Pièces. Contenu construit depuis le registre :

- une tuile par lumière, avec le réglage de luminosité sur les neuf variables ;
- le volet, avec ouverture/fermeture et position ;
- les thermostats, avec la consigne réglable ;
- la température et sa courbe sur 48 h.

Deux rattachements manquants trouvés en construisant : `cover.porte_de_garage` n'avait
aucune zone, et `sensor.temperature_salle_de_bain` non plus.

### La leçon des trois captures

Trois allers-retours, trois erreurs de ma part, toutes invisibles sans le rendu réel :
des badges sans nom, des cartes de zone noyées sous `area-controls`, et un `tap_action`
que j'avais supposé au lieu de le vérifier. **Rien ne remplace une capture d'écran** —
le moteur Puppet, non installé ici, rendrait ces allers-retours inutiles.

## Refonte — étape 4 : Confort et Sécurité

Les deux dernières vues destinées à tout le monde. La barre d'onglets compte désormais
**quatre entrées** — Maison, Pièces, Confort, Sécurité — contre onze sur l'ancien
tableau de bord.

### Confort

| Section | Contenu |
|---|---|
| Chauffage | Les 6 thermostats KNX, consigne réglable dans la tuile, plus le forçage de la salle d'eau |
| Climatisation | Les 2 Daikin, consigne et mode (chaud / froid / auto) en liste déroulante |
| Eau chaude | Température et consigne ECS, état de chauffe, marche/arrêt, bouclage, mode été |
| Températures | Les 7 pièces sur 48 h, et les moyennes intérieur / dehors sur la semaine |

La chaudière elle-même — H1, H2, flamme, modulation, pression — n'est **pas** ici : elle
ira dans Technique. Confort répond à « ai-je chaud », pas à « comment marche la
chaudière ».

### Sécurité

| Section | Contenu |
|---|---|
| Alarme | Panneau avec les quatre modes d'armement, sirène extérieure, simulation de présence |
| Caméras | Interphone, Entrée garage, et la dernière capture du déclenchement |
| Ouvrants | Les 11 capteurs Tydom, tous listés — c'est la vue dédiée, on ne filtre pas |
| Détecteurs | Les 6 capteurs d'alarme, plus visiteur / personne / mouvement de l'interphone |
| Garage | Porte avec position, et son blocage |

Différence de traitement assumée avec la vue Maison : là-bas les ouvrants n'apparaissent
que s'ils sont ouverts, ici ils sont **tous** visibles. Maison signale, Sécurité inventorie.

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
