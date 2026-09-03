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

### Le panneau d'alarme remplacé par une tuile

La carte `alarm-panel` occupait un écran entier de pavé numérique en permanence, alors
que le clavier ne sert qu'au moment d'armer ou de désarmer. Remplacée par une tuile avec
la fonction `alarm-modes` : l'état et les cinq modes tiennent sur une ligne, et le clavier
s'ouvre au besoin. Rien n'est perdu — un appui sur l'icône ouvre la fiche détaillée avec
le panneau complet.

## Refonte — étape 5 : la vue Technique

Réservée au compte admin, comme décidé. Six sections.

| Section | Contenu |
|---|---|
| Chaudière | Flamme, modulation, pression, température extérieure ; circuits H1/H2 avec départ et consigne ; marche/arrêt ; les six vannes |
| Bus KNX | Courant, tension, charge, temps de fonctionnement ; les quatre alarmes du bus ; horloge et dernier événement |
| Rubans LED | Le diagnostic de la phase 2, par ruban, plus les commandes HCL |
| À observer | Les cinq objets KNX dont l'usage reste à confirmer — `0/0/3` et `12/6/0` en écoute seule |
| Système | Température du Pi et du NAS, état des volumes, VMC, sauvegardes et mises à jour |
| Alertes critiques | La liste des appareils notifiés, les deux boutons de test, et les six interrupteurs de criticité repris de l'ancienne vue Réglages |

### ⚠️ Le volume du NAS est à 99 %

Relevé en construisant la section Système : `sensor.stockagereseau_volume_2_volume_utilise`
affiche **99 %** et l'état du volume est passé à « attention ». C'est là que vont les
sauvegardes Home Assistant. La tuile est en rouge dans la vue Technique.

## Refonte — trois retouches après relecture

### Les badges de personne sont partis

`person.marine` et `person.domolaunaguet` affichaient « Maison » ou « Absent » et rien
d'autre — une information que l'on a déjà en entrant dans la maison. Ils occupaient les
deux premières places de la barre de badges de Maison et de Sécurité, devant l'alarme et
les températures. Retirés des deux vues. Sur Sécurité, `cover.porte_de_garage` prend la
place laissée libre : un badge qui, lui, dit quelque chose qu'on ne voit pas depuis le
salon.

### La température extérieure était celle de Météo France, pas la nôtre

Les badges « Dehors » et la courbe hebdomadaire pointaient
`sensor.temperature_exterieure_meteo_france` — la prévision de la station la plus proche.
Or il existe déjà `sensor.moyenne_temperature_exterieure`, qui moyenne trois sources :

| Source | Entité | Relevé au moment du contrôle |
|---|---|---|
| Sonde de la chaudière (KNX 1.1.35) | `sensor.temperature_exterieure_chaudiere` | 26,1 °C |
| Sonde extérieure de la clim | `sensor.clim_chambre_climatecontrol_outdoor_temperature` | 23,5 °C |
| Météo France | `sensor.temperature_exterieure_meteo_france` | 24,7 °C |
| **Moyenne** | `sensor.moyenne_temperature_exterieure` | **24,8 °C** |

Les deux badges et la courbe pointent maintenant la moyenne. Sur la courbe, la légende
devient « Dehors (moyenne) » pour que la différence avec l'ancienne série soit lisible
dans l'historique.

### Les appareils qui reçoivent les notifications sont maintenant visibles

`script.alerte_famille` découvre seul les appareils de l'app Compagnon, ce qui est
pratique mais opaque : rien n'affichait la liste effective. La section « Alertes
critiques » de Technique porte désormais une sous-section **Appareils** qui rejoue la même
découverte que le script — `integration_entities('mobile_app')` filtré sur `notify.` — et
sépare les appareils notifiés (✅) de ceux exclus (⬜, aujourd'hui la tablette murale
`notify.i10_pro`).

⚠️ La liste des exclusions est écrite deux fois : dans `scripts/alerte_famille.yaml` et
dans le template de cette carte. Elles ne se synchronisent pas toutes seules. En exclure
un nouvel appareil demande de modifier les deux — c'est rappelé sous la carte.

Deux boutons complètent la section : **Test normal** et **Test critique**, qui appellent
`script.alerte_famille` avec et sans `critique: true`. De quoi vérifier d'un appui que la
chaîne fonctionne, et que le mode silencieux est bien percé.

## Refonte — le garage et la météo sur l'accueil

### La porte de garage, avec son piège

Une tuile pleine largeur en bas des Raccourcis, avec la fonction `cover-open-close` :
trois touches ▲ ■ ▼. Un appui sur le corps de la tuile ouvre la fiche détaillée, il
n'ouvre pas la porte — impossible de la déclencher par mégarde en faisant défiler.

⚠️ **`switch.blocage_porte_de_garage` n'a aucun retour d'état.** C'est l'adresse KNX
`16/0/8` déclarée sans `state_address` : Home Assistant écrit dessus et affiche ce
qu'il a écrit, sans jamais savoir si l'ordre est passé. Un blocage qui n'a pas pris
s'affiche quand même « activé ».

Ça compte ici, parce que le blocage est piloté automatiquement — `script.depart_maison`
l'active, `script.retour_maison` le désactive — et qu'une porte bloquée refuse de
s'ouvrir sans rien dire. Une seconde tuile, orange, apparaît donc sous la première
**uniquement quand le blocage est marqué actif**, et un appui le relâche. C'est le
meilleur indice dont on dispose, pas une certitude : si un jour la porte refuse de
bouger alors que la tuile orange est absente, c'est le retour d'état qui manque, pas
la commande.

### Le bloc « Dehors »

Trois cartes, toutes natives, entre les Raccourcis et « Allumé en ce moment ».

| Carte | Rôle |
|---|---|
| Vigilance Haute-Garonne | `sensor.31_weather_alert`, masquée tant que l'état vaut `Vert` |
| Prévision | Carte `weather-forecast` native sur `weather.launaguet`, `forecast_type: daily`, conditions du moment plus les jours suivants |
| Pluie dans l'heure | Carte `markdown` sur l'attribut `1_hour_forecast` de `sensor.launaguet_next_rain` |

L'ancien tableau de bord affichait tout ça avec `custom:meteo-france-weather-card`,
une carte HACS. Le nouveau tableau n'utilise aucune ressource HACS, donc la prévision
minute est reconstruite en Jinja.

### Comment se lit la barre de pluie

`sensor.launaguet_next_rain` porte un attribut `1_hour_forecast` : neuf créneaux
étiquetés `0 min` … `55 min`, chacun valant « Temps sec », « Pluie faible »,
« Pluie modérée » ou « Pluie forte ». Les créneaux **ne sont pas réguliers** : cinq
minutes jusqu'à `25 min`, puis dix minutes pour `35`, `45` et `55`. La carte rend donc
un carré par tranche de cinq minutes — un carré pour les six premiers créneaux, deux
pour les trois derniers — soit douze carrés pour une heure pleine :

```
### ☀️ Pas de pluie dans l'heure

maintenant ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜ +1 h
```

```
### 🌧️ Pluie faible dans 25 min

maintenant ⬜⬜⬜⬜⬜🟦🟦🟦🟦🟦🟦⬜ +1 h

25 min : faible · 35 min : modérée · 45 min : faible
```

L'intensité est dans la ligne de détail, pas dans la couleur : la barre ne dit que
« sec » ou « pluie ». Trois nuances de bleu n'existent pas en émojis, et les blocs
semi-graphiques `░▒▓█` n'ont pas la même largeur d'une police à l'autre — l'alignement
serait cassé dès la première substitution de police. Les carrés émojis, eux, sont tous
rendus par la même police.

Le titre lit le premier créneau mouillé et le libellé de Météo-France tel quel, donc
« Pluie modérée dans 35 min » sort directement de la source. Quand l'attribut est
absent — la prévision minute n'est pas disponible partout en France — la carte le dit
au lieu d'afficher une barre vide.

## Refonte — l'accueil repris au rendu

Cinq remarques sur la première version de l'accueil, cinq corrections.

### Un seul bouton, Départ ou Retour

Les deux tuiles occupaient une ligne entière pour proposer en permanence l'action
qu'on ne voulait pas. Elles sont désormais conditionnées sur
`input_boolean.etat_depart_maison` — exactement la mécanique de l'ancien accueil : à
la maison on voit **Départ**, absent on voit **Retour**, jamais les deux. Le bouton
restant prend toute la largeur.

Le Départ garde sa confirmation, le Retour n'en a pas : armer l'alarme en mode
vacances par erreur coûte plus cher que la désarmer.

### Le garage cache ses commandes quand il est bloqué

Deux tuiles s'excluent :

| Blocage | Ce qui s'affiche |
|---|---|
| Inactif | « Porte de garage », avec les trois touches ▲ ■ ▼ |
| Actif | « Garage bloqué par l'alarme », en orange, avec un interrupteur pour le relâcher |

Les commandes disparaissent quand elles ne serviraient à rien — c'était la demande.

⚠️ **Les deux conditions ne sont pas symétriques, et c'est voulu.** La tuile de
commande est conditionnée en négatif (`state_not: 'on'`), la tuile « bloqué » en
positif (`state: 'on'`). Au redémarrage, `switch.blocage_porte_de_garage` passe
quelques secondes par `unavailable` : avec deux conditions positives, le garage
disparaîtrait complètement de l'accueil pendant ce temps. Avec celle-ci, ce sont les
commandes qui restent — le bon défaut quand on ne sait pas.

Le nom dit « par l'alarme » parce que c'est ce qui se passe en pratique : seul
`script.depart_maison` pose ce blocage, et il arme l'alarme en mode vacances dans le
même mouvement. Rien n'interdit de basculer le switch à la main depuis Sécurité, et
le libellé serait alors approximatif.

### La météo réduite de moitié

`show_current: false` sur la carte `weather-forecast`. Le bloc « conditions du
moment » répétait la première colonne de la prévision — mêmes mini et maxi du jour —
et la température extérieure est déjà dans les badges, en moyenne des trois sondes.
La carte perd la moitié de sa hauteur sans rien perdre d'utile. Repasser le drapeau à
`true` restaure le bloc.

### Les lumières allumées en grille

`entity-filter` rend maintenant une carte `glance` au lieu d'une carte `entities` :
une grille d'icônes sur trois colonnes au lieu d'une ligne pleine largeur par lampe,
soit le tiers de la hauteur. Le titre passe en `heading_style: subtitle` pour rester
en retrait.

Le contrôle individuel est conservé, il change juste de geste : **un appui éteint la
lampe** (`tap_action: toggle`), un appui long ouvre sa fiche.

### La section « La maison » est supprimée

Six cartes de zone en bas de l'accueil, quand l'onglet Pièces en présente vingt et
une rangées par étage. La version courte ne rendait service à personne.

L'accueil compte donc quatre sections : Attention (masquée quand tout va bien),
Raccourcis, Allumé en ce moment (masquée quand tout est éteint), Dehors.

## Refonte — deux vrais bugs trouvés au second rendu

### Les deux cartes vides de la section Attention

Un test de Départ a armé l'alarme, la section Attention est apparue — avec la carte
« Alarme », attendue, mais **aussi « Ouvrants ouverts » et « Défaut ruban LED »,
vides**. Rien ne les justifiait : au moment du relevé, les onze ouvrants Tydom
étaient tous `LOCKED` et les quatre capteurs de défaut LED tous à `off`.

Cause : **`entity-filter` ne se masque pas tout seul.** Son option `show_empty` vaut
`true` par défaut, et la carte intérieure s'affiche alors avec son titre et son
icône, sans aucune ligne. Le commentaire d'en-tête de `maison.yaml` affirmait
l'inverse depuis l'étape 2 — c'était faux.

Corrigé par `show_empty: false` sur les trois `entity-filter` du tableau. La section
Attention n'affiche plus que les cartes qui ont quelque chose à dire.

### L'appui court n'éteignait pas la lampe

Le `tap_action: toggle` était bien posé sur la carte `glance` — mais **la carte
`glance` ne connaît pas `tap_action` au niveau de la carte.** La documentation ne le
décrit qu'entité par entité. L'option était ignorée sans erreur, et l'appui
retombait sur la fiche détaillée.

Les 31 lampes portent maintenant chacune leur `tap_action: toggle` et leur
`hold_action: more-info`. Appui court pour éteindre, appui long pour la fiche.

### Le blocage du garage se relâchait au moindre appui

Trois versions ont été nécessaires.

| Version | Ce qui n'allait pas |
|---|---|
| Tuile de switch nue | `tap_action` vaut `toggle` par défaut : appuyer n'importe où relâchait le blocage |
| `tap_action: more-info` + feature `toggle` | Le bandeau de la feature faisait la même chose d'un seul doigt |
| **Tuile d'information seule** | — |

La version retenue n'a **aucune commande** : ni feature, ni action au doigt. Tant que
le blocage est actif, la porte n'est pas manœuvrable depuis l'accueil, et c'est le
but. `tap_action: more-info` ouvre la fiche du switch, seul endroit d'où le relâcher
volontairement.

### La météo passe à l'horaire pour tenir en deux rangées

`grid_options` seul ne pouvait pas la réduire. `rows: 2` **rognait les températures
minimales**, et `rows: 3` valait exactement la hauteur automatique : avec
`show_current: false`, la carte quotidienne était déjà à son minimum, le reste étant
sa marge interne — que seul `card-mod` (HACS, exclu) pourrait toucher.

Le levier était donc le **contenu**. Une prévision quotidienne affiche jour, icône,
maxi *et* mini ; l'horaire n'a qu'une température par créneau, soit une ligne de
moins. `forecast_type: hourly` + `rows: 2` tient sans rien rogner. On échange les cinq
jours contre les prochaines heures — ce qui, sur un écran d'accueil, répond plutôt
mieux à « je sors, je prends quoi ».

`weather.launaguet` annonce `supported_features = 3`, soit quotidien + horaire : le
bit 2 est bien là. Une entité météo qui ne le porterait pas rendrait la carte vide.

L'autre voie, écartée : une carte `markdown` alimentée par un capteur modèle
déclenché appelant `weather.get_forecasts`, qui donnerait les cinq jours en une ou
deux lignes de texte — mais au prix d'un appel de service périodique dans la
configuration.

## ⚠️ L'éclairage du jardin manque au groupe « Toutes les Lumières »

Trouvé en vérifiant si la carte pouvait pointer un helper plutôt que 31 entités.

| | |
|---|---|
| Membres de `light.toutes_les_lumieres` | **30** |
| Lampes réelles du système | **31** |
| Absente du groupe | `light.eclairage_jardin` |

Conséquence : allumé seul, l'éclairage du jardin laisse `light.toutes_les_lumieres`
à `off`. La section « Allumé en ce moment » ne serait pas apparue, et une extinction
générale par le groupe ne l'aurait pas éteint.

Contourné dans le tableau — la section teste maintenant le groupe **OU**
`light.eclairage_jardin`. Le contournement est à retirer une fois le groupe complété
dans Paramètres > Appareils et services > Aides.

### Pourquoi la carte liste 31 entités et pas un groupe

`entity-filter` exige une liste plate d'entités : on ne peut pas lui donner un groupe,
il ne l'étendrait pas. La liste de la carte est donc tenue à la main, et c'est cette
comparaison avec le helper qui a révélé le trou. À refaire après toute création de
lampe.

## Refonte — la tuile de blocage rendue inerte, la météo réécrite

### Le garage : trois essais avant la bonne réponse

| Essai | Ce qui n'allait pas |
|---|---|
| Tuile de switch nue | `tap_action` vaut `toggle` par défaut : appuyer n'importe où relâchait |
| `tap_action: more-info` + feature `toggle` | Le bandeau de la feature relâchait d'un seul doigt |
| Feature retirée, `tap_action: more-info` | La fiche du switch s'ouvrait, avec son interrupteur dedans |
| **`tap_action` et `hold_action` à `none`** | — |

La tuile est maintenant **inerte**. Tant que le blocage est actif, la porte n'est
pas manœuvrable depuis l'accueil, et rien sur cette carte ne relâche quoi que ce
soit. Le relâchement volontaire se fait depuis **Sécurité**, ou par le script
**Retour maison**.

Elle porte aussi `rows: 2`, comme la tuile de commande qu'elle remplace : sans ça,
la section changeait de hauteur au gré du blocage.

### La météo : une carte markdown et un capteur de prévision

Quatre tentatives sur la carte native avant d'admettre qu'elle ne se réduisait pas.

| Tentative | Résultat |
|---|---|
| `show_current: false` | Encore trop haute |
| `rows: 2` en quotidien | Rogne la ligne des minimales |
| `rows: 3` en quotidien | Vaut exactement la hauteur automatique |
| `forecast_type: hourly` | Tient en deux rangées, mais perd les jours |

`grid_options` ne pouvait pas la réduire : le reste de sa hauteur est sa marge
interne, que seul `card-mod` (HACS, exclu) atteindrait. Il fallait changer le
**contenu**.

Depuis Home Assistant 2024.4, une entité météo n'expose plus sa prévision en
attribut — vérifié sur `weather.launaguet`, qui ne porte que les conditions du
moment. Il faut appeler `weather.get_forecasts`, ce qu'un template de carte ne sait
pas faire. D'où un capteur modèle **déclenché**, ajouté à `configuration.yaml` :

```yaml
  - trigger:
      - trigger: homeassistant
        event: start
      - trigger: time_pattern
        minutes: "/30"
    action:
      - action: weather.get_forecasts
        target:
          entity_id: weather.launaguet
        data:
          type: daily
        response_variable: reponse
    sensor:
      - name: "Prévisions Launaguet"
        unique_id: previsions_launaguet_quotidiennes
        state: "{{ reponse['weather.launaguet'].forecast[0].condition }}"
        attributes:
          jours: "{{ reponse['weather.launaguet'].forecast[:6] }}"
```

La carte markdown le rend en deux lignes :

```
### ☀️ Aujourd'hui 33 / 15 °C

ven ☀️ 35/16 · sam ☀️ 36/19 · dim ☀️ 38/21 · lun ☀️ 31/20
```

Le jour même en titre — c'était la demande — et les quatre suivants en dessous. Les
noms de jours sont mappés à la main : `strftime` ne se localise pas dans les
templates Home Assistant, `%a` sort en anglais.

⚠️ **Le capteur ne se remplit pas au rechargement des templates.** `template.reload`
crée l'entité mais n'exécute pas son déclencheur : elle reste à `unknown` jusqu'au
prochain top de demi-heure ou au prochain démarrage de Home Assistant. La carte
affiche « Prévision en attente » entre-temps, plutôt qu'un cadre vide.

## Le groupe « Toutes les Lumières » est complet

`light.eclairage_jardin` a été ajouté au groupe le 3 septembre.

| | Avant | Après |
|---|---|---|
| Membres du groupe | 30 | **31** |
| Lampes réelles | 31 | 31 |
| Absentes | `light.eclairage_jardin` | aucune |

Conséquence immédiate : l'éclairage du jardin compte désormais dans l'état du
groupe, et une extinction générale l'éteint.

Le contournement posé dans le tableau — la section « Allumé en ce moment » testait
le groupe **OU** `light.eclairage_jardin` — a été retiré dans la foulée. Elle teste
de nouveau le seul groupe.

## Phase 2 KNX — vérification à 18 h (3 septembre)

Relevé sur les 24 h suivant la mise en service, plus 7 jours d'historique pour les
diagnostics du bus. **Aucune correction n'a été appliquée : l'hypothèse d'inversion
était fausse, et le reste relève d'une décision à prendre.**

### Le diagnostic 24 V des rubans : le sens est bon, pas d'`invert`

L'hypothèse était qu'un ruban allumé avec un capteur 24 V resté à `off` trahirait un
sens inversé. Les faits disent l'inverse — le capteur suit le ruban, à chaque fois.

**Ruban salon piano** (`1.1.15`) :

| Ruban | Capteur 24 V | Écart |
|---|---|---|
| 17:02:39 allumé | 17:02:40 on | +0,9 s |
| 20:33:33 éteint | 20:33:45 off | +12,4 s |
| 23:16:17 allumé | 23:16:18 on | +0,5 s |
| 08:07:20 éteint | 08:07:32 off | +12,8 s |
| 08:46:35 allumé | 08:46:36 on | +0,9 s |

**Ruban double hauteur** (`1.1.37`) : même schéma, +0,5 à +0,9 s à l'allumage et
**+23,8 s** à l'extinction.

Deux détails que seule l'observation donnait :

- **L'allumage est quasi immédiat, l'extinction non** — 12 à 24 secondes de retard.
  C'est la temporisation de l'alimentation, pas un défaut.
- **Les impulsions courtes sont filtrées.** Le ruban salon piano a été éteint puis
  rallumé en 3 s (20:33:24 → 20:33:27) et en 5 s (07:20:36 → 07:20:41) : le capteur
  24 V n'a pas bougé, la temporisation d'extinction n'ayant pas expiré.

⚠️ **Le nom induit en erreur.** « Alimentation 24 V » suggère un diagnostic de santé
de l'alimentation — il serait alors à `on` en permanence. Il s'agit en fait de
**« sortie 24 V active »**, qui recopie l'état du ruban. Renommer casserait les
`entity_id` et le tableau de bord ; à trancher.

### Jour / nuit : l'adresse ne dit rien

`binary_sensor.etat_jour_1_nuit_0` (`12/3/0`) n'a **rien reçu en 18 h**, coucher et
lever de soleil compris. Il aurait dû basculer deux fois. Le sens ne peut donc pas
être déterminé, et il n'y a rien à inverser : l'adresse est muette, pas à l'envers.

### HCL et objets « à observer » : rien reçu non plus

| Entité | Reçu en 18 h |
|---|---|
| `switch.hcl_ruban_led_salon` | rien (`unknown`) |
| `switch.hcl_ruban_led_double_hauteur` | rien (`unknown`) |
| `binary_sensor.hcl_en_cours_ruban_led_salon_piano` | rien |
| `sensor.bus_statut_de_la_visualisation` | rien (`unknown`) |
| `binary_sensor.bus_defilement_du_message` | rien |
| `binary_sensor.bus_confirmation_menu` | rien |
| `binary_sensor.bus_ordre_de_reset` | rien |
| `binary_sensor.volets_mesure_du_temps_de_deplacement` | rien |

Candidats à la suppression, non supprimés.

### L'horloge du bus : juste

| Entité | Valeur | Reçue à | Écart |
|---|---|---|---|
| `datetime.bus_horodatage` | 08:53:43 | 08:53:43,55 | 0,55 s |
| `time.bus_heure` | 08:53:43 | 08:53:43,16 | 0,16 s |
| `date.bus_date` | 2026-09-03 | 00:03:43 | bascule correcte |

Télégramme toutes les ~10 minutes. Aucune dérive.

## ⚠️ Trouvaille non prévue : 32 entités KNX sur 158 sont muettes

En élargissant le contrôle à toute l'intégration : **32 entités n'ont rien reçu
depuis le redémarrage.** Le journal le confirme côté bus — `xknx` a produit
**1 086 avertissements** en 20 h, par paires « Could not sync group address X » +
« KNX bus did not respond in time (2.0 secs) », sur une soixantaine d'adresses,
répétés à peu près toutes les heures.

Une partie est normale : les interrupteurs sans `state_address` (H1, H2, ECS, mode
été, sirène, forçage salle d'eau) sont optimistes par construction, et les entités
de diagnostic de l'intégration ne changent qu'à la reconnexion.

**Le reste ne l'est pas — et me concerne directement.**

| Entité | État | Affichée dans |
|---|---|---|
| `sensor.courant_du_bus` | `unknown` | Technique, tuile « Courant » |
| `sensor.tension_du_bus` | `unknown` | Technique, tuile « Tension » |
| `sensor.utilisation_du_bus` | `unknown` | Technique, **badge « Bus »** + tuile « Charge » |
| `sensor.temps_de_fonctionnement` | `unknown` | Technique, tuile « Fonctionnement » |
| `sensor.temps_de_fonctionnement_depuis_redemarrage` | `unknown` | — |
| `sensor.dernier_evennement` | `unknown` | Technique, « Horloge et journal » |
| `binary_sensor.alarme_depasement_temperature` | jamais reçu | Technique, « Alarmes du bus » |
| `binary_sensor.alarme_depasement_courant` | jamais reçu | Technique, « Alarmes du bus » |
| `binary_sensor.alarme_tension_trop_basse` | jamais reçu | Technique, « Alarmes du bus » |
| `binary_sensor.alarme_trafic_bus` | jamais reçu | Technique, « Alarmes du bus » |
| `sensor.temperature_h2_actuelle` | `unknown` | Technique, « Circuits » |

**Ce n'est pas une panne récente.** Sur les 7 jours d'historique conservés, ces
capteurs n'ont jamais porté autre chose que `unknown` ou `unavailable` — pas une
seule valeur, jamais. Ils sont antérieurs à la phase 2 et n'ont jamais fonctionné.

La section « Bus KNX » de la vue Technique a donc été construite sur des entités
supposées vivantes, sans vérification. C'est mon erreur : j'ai repris les noms de
l'ancienne configuration en tenant leur fonctionnement pour acquis.

Trois voies, à trancher :

1. **Réveiller la source.** Ces adresses correspondent à une alimentation KNX à
   diagnostic. Si le module existe, ses objets sont probablement non liés dans ETS,
   ou son envoi cyclique est désactivé. C'est la seule voie qui rende l'information.
2. **`sync_state: false`** sur les adresses mortes — supprime les 1 086
   avertissements quotidiens et le trafic de lecture inutile, sans rien retirer.
3. **Retirer** les entités et les cartes correspondantes.

### Système : rien à signaler

| | |
|---|---|
| Base recorder | **202,13 Mio** — pas de gonflement |
| Disque | 16,0 Go utilisés sur 457,7 |
| Supervisor | `healthy: true`, `supported: true` |
| Horloge | `ntp_synchronized: true` |
| Journal hôte, recherche `usb` | aucune ligne — pas de reset UAS à cette heure (la mise à jour de 09:53 en déclenchera douze, voir plus bas) |

À noter : trois interruptions le 2 septembre — 03:00, 10:11 et 15:00. Celles de
10:11 et 15:00 sont les rechargements de l'entrée KNX. Celle de **03:00 dure 2 min 50
et touche aussi les entités Tydom**, donc au-delà de KNX ; sans trace au journal
hôte, elle reste inexpliquée.

## Purge KNX du 3 septembre — 20 objets retirés

Suite donnée à la vérification : suppression des objets qui n'ont jamais rien envoyé,
dans `knx.yaml`, dans le registre d'entités, et dans les deux tableaux de bord.

### Ce qui a été retiré

| Origine | Adresses | Objets |
|---|---|---|
| Alimentation KNX | `0/1/0` `0/1/1` `0/1/2` `0/1/3` | les quatre alarmes du bus |
| | `0/2/0` `0/3/0` `0/4/2` | courant, tension, charge |
| | `0/0/1` `0/0/2` | temps de fonctionnement |
| | `0/4/0` `0/4/1` | statut de visualisation, dernier événement |
| | `0/4/3` `0/4/4` `0/0/3` | écran et menu |
| Phase 2 | `12/3/0` | jour / nuit |
| | `6/3/7` | HCL en cours ruban salon piano |
| | `6/2/13` `6/2/7` `6/4/13` `6/4/7` | les deux commandes HCL |
| | `12/6/0` | étalonnage du temps de déplacement des volets |
| Chaudière | `17/0/3` | « Température H2 actuelle » |

**Le cas `17/0/3` méritait une vérification avant de couper.** Un circuit de chauffage
muet en septembre peut simplement être à l'arrêt. Mais `17/0/2` (consigne H2) et
`binary_sensor.etat_h2` parlent toutes les dix minutes, et `sensor.temperature_h1_actuelle`
donne 29,8 °C : le circuit H2 est vivant, c'est l'adresse qui est fausse. Il faudra la
retrouver dans ETS pour récupérer la température de départ H2.

### Le résultat, mesuré

Comptage des adresses en échec de lecture sur un cycle horaire, avant et après :

| | Adresses en échec par cycle | Avertissements par jour |
|---|---|---|
| Cycle de 09:00 | **26** | ~1 250 |
| Cycle de 09:15, après purge | **7** | ~340 |

Entités KNX : **158 → 138**. Les vingt entrées orphelines laissées dans le registre
après le rechargement ont été retirées dans la foulée — sans ça, elles seraient
restées affichées en `indisponible`.

⚠️ **Les sept adresses restantes ne sont pas à supprimer.** Six sont les objets de
mode des thermostats — `3/1/4` `7/1/4` `8/1/4` `9/1/4` `10/1/4` `11/1/4` — qui
appartiennent à des `climate` parfaitement fonctionnels : ils émettent spontanément
mais ne répondent pas à une demande de lecture. La septième est `12/5/2`
(`detection chan 1`), muette elle aussi mais dont le rôle n'est pas établi.

Pour taire ce reste sans rien perdre : `sync_state: false` sur les six thermostats.
Non fait — à décider.

### Les cartes

**Vue Technique du nouveau tableau** — la section « Bus KNX » perd ses quatre tuiles
et sa liste d'alarmes, il ne reste que l'horodatage, avec une note expliquant
pourquoi. La section « À observer » disparaît entièrement. « Commande HCL » et la
ligne « HCL en cours » quittent les rubans LED, et « Température H2 actuelle » quitte
les circuits de la chaudière. Six sections deviennent cinq, et le badge « Bus » de
l'en-tête est retiré.

**Vue Diag de l'ancien tableau** — celui encore par défaut — trois sections partent :
« HCL », « Bus KNX — a observer » et « Jour / nuit ». Restent les diagnostics des deux
rubans et l'horloge du bus. Une section « Sortie 24 V et rubans » est ajoutée : elle
superpose chaque ruban et sa sortie 24 V sur 48 h, ce qui rend la corrélation
vérifiable d'un coup d'œil plutôt que sur parole.

## Refonte — l'accueil resserré

Sept retouches d'un coup, toutes tournées vers la cohérence visuelle.

### Les textes sont centrés dans les boutons

`vertical: true` sur toutes les tuiles d'action : icône au-dessus, libellé centré
dessous. En horizontal, l'icône colle à gauche et le texte flotte au milieu d'un grand
vide — c'est exactement ce que donnaient les tuiles pleine largeur « Départ »,
« Retour » et « Garage bloqué ».

### « Raccourcis » se scinde en « Présence » et « Général »

| Section | Contenu |
|---|---|
| **Présence** | Le seul bouton Départ **ou** Retour, pleine largeur |
| **Général** | Tout éteindre, Garage, Volets RDC, Volets étage |

Départ / Retour sort des commandes courantes parce que c'est la seule action qui change
l'état de la maison entière — alarme, simulation de présence, blocage du garage.

### « Général » est une grille 2×2 rigoureusement régulière

Quatre tuiles au même gabarit : 6 colonnes, 2 rangées, verticales.

```
┌─────────────────┬─────────────────┐
│  Tout éteindre  │     Garage      │
├─────────────────┼─────────────────┤
│   Volets RDC    │  Volets étage   │
└─────────────────┴─────────────────┘
```

La tuile « Garage bloqué » reprend **exactement** le même gabarit que la tuile de
commande qu'elle remplace : sans ça, la grille se déforme selon l'état du blocage.

### « Lumières » devient « Tout éteindre »

L'ancienne tuile affichait « Allumé » ou « Éteint » — une information qu'on a déjà par
la section « Allumé en ce moment » juste dessous — et un deuxième appui rallumait tout.

La nouvelle est un **bouton d'action** : son `tap_action` appelle `light.turn_off` sur
le groupe. Un appui éteint, il ne rallume jamais. L'entité reste le groupe, ce qui fait
que la tuile se colore tant qu'il reste quelque chose à éteindre.

### Un bouton de volets par niveau

`cover.volets_rez_de_chaussee` (Buanderie, Bureau, Salon Télé) et `cover.volets_etage`
(chambres Auguste, Margaux, parentale, salle d'eau, salle de bain). **Les deux groupes
existaient déjà** — 3 + 5 = 8, le compte exact de `cover.tous_les_volets` — il n'y avait
rien à créer. Chacun occupe la moitié de la largeur au lieu de la tuile unique
précédente.

### La météo et la pluie fusionnent

Deux cartes markdown qui se suivaient, deux informations de même nature. Une seule
désormais, séparée par un filet :

```
### ☀️ Aujourd'hui 33 / 15 °C

ven ☀️ 35/16 · sam ☀️ 34/20 · dim ☀️ 38/20 · lun ☀️ 31/20

---
☀️ **Pas de pluie dans l'heure**

maintenant ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜ +1 h
```

### « Dehors » devient « Extérieur » sur les badges, « Météo » sur la section

Les badges de température de Maison et de Confort disent « Extérieur », ainsi que la
légende de la courbe hebdomadaire. La section, elle, s'appelle **« Météo »** — ni l'un
ni l'autre : « Extérieur » y désignerait la zone du même nom, qui a sa propre page de
pièce dans l'onglet Pièces.

## Refonte — l'accueil dégraissé

Trois corrections après le rendu de la version resserrée.

### La barre de pluie disparaît quand il ne pleut pas

Douze carrés blancs pour dire qu'il ne se passe rien, c'est douze carrés de trop. À sec,
la carte se termine par une ligne :

```
### ☀️ Aujourd'hui 33 / 15 °C

ven ☀️ 35/16 · sam ☀️ 34/20 · dim ☀️ 38/20 · lun ☀️ 32/20

☀️ Pas de pluie dans l'heure
```

La barre, le filet de séparation et le détail des créneaux ne sortent que si de la pluie
est annoncée. Les deux branches ont été vérifiées au moteur de templates avant écriture,
la sèche sur les données réelles et l'humide sur un jeu simulé.

### Les deux blocs de boutons rétrécissent

| | Avant | Après |
|---|---|---|
| Départ / Retour | pleine largeur, 2 rangées | **demi-largeur**, 2 rangées |
| Les quatre tuiles de « Général » | 6 colonnes, 3 rangées | 6 colonnes, **2 rangées** |

Sur « Général », trois rangées valaient 184 px alors qu'une tuile verticale avec sa
rangée de touches en occupe environ 120 : un tiers de vide.

⚠️ Sur Départ / Retour, **la hauteur ne peut pas descendre sous deux rangées** tant que
`vertical: true` est posé : icône et libellé empilés dépassent les 56 px d'une rangée et
se feraient rogner. C'est donc la largeur qui a été divisée. Pleine largeur, le bouton
faisait un pavé de 120 px pour un seul mot.

## ⚠️ `grid_options.rows` ne contraint pas une tuile verticale à features

Le rendu a montré que la grille 2×2 n'était pas régulière du tout : les deux tuiles du
haut faisaient 120 px comme demandé, les deux volets 184 px — trois rangées, alors que
`rows: 2` était posé sur les quatre.

**Une tuile `vertical: true` qui porte des `features` s'étale sur trois rangées quoi
qu'on demande.** Elle empile icône, nom, état, puis la rangée de touches : le contenu
dépasse 120 px et la carte grandit. `grid_options.rows` agit ici comme un plancher, pas
comme un plafond — l'inverse du comportement observé sur la carte météo, où il rognait.

En **horizontal**, la même tuile tient en deux rangées : icône, nom et état partagent
une seule ligne au-dessus des touches. C'est exactement ce que faisait la tuile
« Volets » d'origine, avant qu'on cherche à centrer.

D'où le panachage retenu :

| Tuile | Disposition | Pourquoi |
|---|---|---|
| Tout éteindre, Garage bloqué | **verticale** | Pas de touches — remplit bien ses 120 px, texte centré |
| Garage, Volets RDC, Volets étage | **horizontale** | Porte des touches — ne tient en 120 px qu'ainsi |

Les quatre cases font la même taille, ce qui est ce qui compte à l'œil ; l'alignement
interne diffère et cela ne se remarque pas.

Le bouton Départ / Retour repasse pleine largeur sur **une** rangée, donc horizontal.
Deux essais ont précédé : pleine largeur sur deux rangées faisait un pavé de 120 px pour
un mot ; en demi-largeur, la moitié droite de la section restait vide. À une rangée il se
lit comme une barre d'action, pas comme une boîte à moitié remplie. *(Il finira en carte
`button` et non en tuile — voir plus bas.)*

## Les volets : la flèche dit ce qui va se passer

Idée de Mathias, meilleure que ce que je proposais : plutôt que de retirer les touches
et de renvoyer vers la fiche, garder un appui direct sur la tuile — mais afficher un
symbole indiquant le sens.

Deux tuiles par groupe, **une seule visible** selon l'état :

| État du groupe | Tuile affichée | Un appui déclenche |
|---|---|---|
| `closed` | ↑ **Volets RDC** | `cover.open_cover` |
| tout le reste | ↓ **Volets RDC** | `cover.close_cover` |

La flèche annonce donc **l'action à venir**, pas l'état courant — et l'action appelée
correspond exactement à ce que la flèche montre, sans passer par un `toggle` dont il
faudrait deviner le sens.

Gain de place : la tuile tombe à **une rangée, 56 px au lieu de 120** pour la paire. Un
appui long ouvre toujours la fiche complète, avec la position au pourcentage — ce qu'on
n'avait pas avec les touches ▲■▼.

### L'appui long ouvre la page Volets

Une vingt-deuxième sous-vue, `/maison-v2/volets`, atteinte par un appui long sur l'une
des deux tuiles :

| Bloc | Contenu |
|---|---|
| Tous les volets | Le groupe des huit |
| Rez-de-chaussée | Le groupe du niveau, puis Buanderie, Bureau, Salon Télé |
| Étage | Le groupe du niveau, puis les cinq volets |

Chaque tuile porte `cover-open-close` : c'est là que se trouve **l'arrêt en cours de
course**, que les flèches de l'accueil ne donnent pas.

`cover-position` a été retiré au premier rendu. Le curseur triplait la hauteur de chaque
tuile — icône et nom, puis les touches, puis la barre — pour un réglage qu'on ne fait pas
depuis une liste de onze volets. Sans lui la tuile tient en deux rangées, et **deux
tiennent par ligne** : la page passe d'environ 1450 px à 760.

La position reste accessible dans la fiche de chaque volet, et les vingt et une
sous-vues de pièce la gardent — c'est là qu'on règle un volet précis au pourcentage.
Seul le groupe des huit reste pleine largeur : seul de sa section, il remplirait mal une
demi-ligne.

Son `back_path` pointe vers `/maison-v2/maison` et non vers `/pieces` comme les vingt et
une sous-vues de pièce : on y arrive depuis l'accueil, le bouton retour doit y ramener.

⚠️ Trois pièges traités :

- **`icon_tap_action` en plus de `tap_action`.** Sur une tuile, l'icône a sa propre
  action : sans ça, appuyer sur la flèche elle-même aurait ouvert la fiche au lieu de
  bouger le volet.
- **La condition de descente est négative** (`state_not: closed`), ce qui couvre `open`,
  `opening`, `closing` et `unknown`. La tuile ne disparaît donc jamais, y compris
  pendant le mouvement — où l'appui sert alors à inverser.
- **`icon_hold_action` double `hold_action`**, pour la même raison : sans lui, un appui
  long sur la flèche ouvrirait la fiche au lieu de la page Volets.

## ⚠️ Les ancres YAML de `maison.yaml`

En construisant ces tuiles, la régénération du fichier a produit un `maison.yaml`
illisible : `found duplicate anchor 'id001'`.

PyYAML émet une ancre `&id001` dès qu'un même **objet Python** apparaît deux fois dans
la structure, et une alias `*id001` aux occurrences suivantes. Le fichier en comptait
déjà **63**, héritées des cartes de zone de la vue Pièces où `alert_classes: []` était
un objet partagé. En régénérant un autre bloc séparément, un second `&id001` est apparu
et les deux se sont disputé l'identifiant.

Correction : `Dumper.ignore_aliases = lambda *a: True` et régénération de la totalité du
bloc `views:`. Le fichier ne contient plus aucune ancre. C'est un artefact de
sérialisation seulement — le tableau de bord en direct n'a jamais été affecté, il est
stocké en JSON.

## L'ordre de l'accueil, et le bouton Présence dégonflé

Ordre retenu, de haut en bas :

| Section | Ce qu'elle répond |
|---|---|
| Attention | Y a-t-il un problème ? *(masquée si non)* |
| Météo | Qu'est-ce qu'il fait dehors ? |
| Général | Qu'est-ce que je commande ? |
| Présence | Je pars ou je rentre |
| Allumé en ce moment | Qu'est-ce qui est allumé ? *(masquée si rien)* |

Les deux sections de queue sont les plus effaçables : Départ / Retour ne sert qu'aux
deux bouts de la journée, et « Allumé en ce moment » disparaît complètement quand tout
est éteint. Les mettre en bas garde le haut de page stable.

### ⚠️ Une tuile ne sait pas être centrée *et* sur une rangée — la carte `button`, si

Six essais sur ce seul bouton, tous sur une carte `tile`, tous obligés de choisir :

| Essai | Résultat |
|---|---|
| Pleine largeur, 2 rangées, centré | Jugé trop gros |
| Demi-largeur, 2 rangées, centré | La moitié droite de la section reste vide |
| Pleine largeur, 1 rangée, à gauche | Compact, mais non centré |
| Pleine largeur, 2 rangées, centré | Toujours trop gros |
| Pleine largeur, 1 rangée, à gauche | Pas centré |
| Pleine largeur, 2 rangées, centré | Toujours trop gros |

La contrainte est structurelle et sans contournement **sur une tuile** : le centrage
n'y existe que via `vertical: true`, qui empile icône et libellé au-delà des 56 px
d'une rangée. J'ai fait six allers-retours en cherchant le compromis dans la mauvaise
carte, jusqu'à en conclure que la demande était contradictoire. Elle ne l'était pas :
c'était la carte qui était mauvaise.

**La carte `button` centre son contenu par construction**, sans avoir besoin d'empiler
quoi que ce soit. Avec `show_icon: false` il ne reste que le libellé, qui tient
largement dans une rangée :

```yaml
type: button
entity: script.depart_maison
name: Départ
show_icon: false          # ← sans ça, icône AU-DESSUS du nom : deux rangées à nouveau
show_name: true
show_state: false
grid_options: {columns: full, rows: 1}
```

**Retenu : centré, pleine largeur, une rangée — 56 px au lieu de 120.** Le prix payé
est l'icône : la carte `button` empile toujours icône et nom, jamais côte à côte. Pour
un bouton pleine largeur dont le libellé tient en un mot, le texte seul suffit.

*Leçon générale : avant de conclure qu'une demande de mise en page est contradictoire,
vérifier que la contrainte vient bien du besoin et non du type de carte choisi.*

## Où en est la refonte

| Étape | État |
|---|---|
| 1. Registre des zones | ✅ 3 étages, 21 zones, tout rattaché |
| 2. Vue Maison | ✅ |
| 3. Vue Pièces + 21 sous-vues | ✅ |
| 4. Confort et Sécurité | ✅ |
| 5. Technique | ✅ |
| 6. Bascule | à faire — `maison-v2` n'est pas encore le tableau par défaut |

L'ancien tableau `lovelace` et ses onze vues restent intacts et par défaut.

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

### La montée en 2026.9.0 — le bug pris sur le fait

Première mesure chiffrée du défaut, le 3 septembre 2026. Mathias a lancé la mise à
jour du Core (2026.8.3 → **2026.9.0** ; l'OS reste en 18.2). Elle a réussi, mais le
pont a lâché pendant toute la durée de l'opération.

| Heure (Paris) | |
|---|---|
| 09:51:40 | Sauvegarde automatique avant mise à jour |
| 09:53:18 → 10:09:10 | **12 resets UAS**, environ un par minute |
| 09:53:18 → 10:05:54 | **14 erreurs d'E/S**, toutes en lecture |
| 10:06:21 | Le recorder redémarre — Home Assistant est revenu |
| 10:09:10 | Dernier reset |

La séquence, identique à chaque fois :

```
sd 0:0:0:0: [sda] tag#0 uas_eh_abort_handler 0 uas-tag 6 inflight: CMD
sd 0:0:0:0: [sda] tag#0 CDB: opcode=0x2a 2a 00 32 e7 48 a0 00 00 08 00
scsi host0: uas_eh_device_reset_handler start
usb 2-2: reset SuperSpeed USB device number 2 using xhci_hcd
usb 2-2: enable of device-initiated U1 failed.
scsi host0: uas_eh_device_reset_handler success
```

Deux détails confirment le diagnostic posé jusqu'ici sur hypothèse :

- **`opcode=0x2a`** est un SCSI `WRITE(10)`. Les commandes abandonnées sont des
  écritures — c'est bien la charge d'écriture qui déclenche, pas la lecture.
- **`enable of device-initiated U1 failed`** est l'échec de négociation de l'état de
  veille du lien USB 3, signature connue du pont Realtek RTL9210.

Chaque reset s'est terminé en `success` : le pilote a récupéré à chaque fois. Mais
**14 erreurs d'E/S ont tout de même remonté aux couches supérieures** — des lectures
qui ont réellement échoué, pas des commandes rejouées en silence.

#### Ce qui a tenu, vérifié 47 minutes après

| | |
|---|---|
| Nouveaux resets depuis 10:09:10 | **0** |
| Nouvelles erreurs d'E/S | **0** |
| Erreurs `EXT4`, remontage en lecture seule | aucune |
| Base recorder | intacte — plus ancien enregistrement toujours au 22 août, 202 Mio |
| `current_recorder_run` | inchangé depuis 10:06:21 — pas de redémarrage spontané |
| Supervisor | `healthy: true`, `supported: true` |
| Entités | 441, dont 10 indisponibles — le lot habituel |
| Entités KNX | 138 — la purge du matin a survécu |
| Disque | 18,3 Go pendant la mise à jour, retombé à 15,9 Go (ancienne image nettoyée) |

#### Ce que ça apprend

Le défaut se déclenche sur les **rafales** d'écriture, pas en régime permanent : douze
resets en seize minutes pendant la mise à jour, zéro dans les quarante-sept minutes
qui ont suivi, alors que Home Assistant tournait normalement.

Le réglage `commit_interval: 30` du recorder réduit l'écriture continue et reste utile,
mais il ne peut rien contre une rafale de mise à jour. **`usb-storage.quirks` demeure le
seul remède**, et il attend toujours un accès physique au support.

En pratique : chaque mise à jour est un passage à risque. Celle-ci est passée — le
système de fichiers et la base sont indemnes — mais quatorze erreurs de lecture, c'est
passer près. Sauvegarde vérifiée avant, et pas de mise à jour à distance sans pouvoir
intervenir physiquement en cas de casse.

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
