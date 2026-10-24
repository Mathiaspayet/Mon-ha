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

**⚠️ Corrigé le 22 octobre 2026 — ce paragraphe était faux.** Il affirmait que « le
vocabulaire Tydom est `LOCKED` / `UNLOCKED` » et que les conditions filtraient sur
`UNLOCKED` et `OPENED`. `OPENED` n'existe pas : les neuf fenêtres remontent `OPEN_FRENCH`
ou `OPEN_HOPPER` et n'étaient donc **jamais** signalées. Vocabulaire réel et correctif :
voir « 22 octobre 2026 — le vocabulaire des ouvrants, vérifié ». Les conditions portent
désormais sur onze capteurs modèles en français, et gardent la correspondance
**positive** pour qu'un état transitoire au démarrage ne déclenche pas de fausse alerte.

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

## Diagnostic du 4 septembre 2026 — la sous-tension pendant la sauvegarde

Passage sur 24 h. Le résultat qui compte n'était pas dans les journaux de Home
Assistant mais dans ses réparations : **`rpi_power / under_voltage_detected`,
sévérité critique**, apparue dans la nuit.

| Heure | Événement |
|---|---|
| 05:10:49 | Sauvegarde automatique démarrée |
| **05:11:22** | `binary_sensor.rpi_power_status` → **on** (rail 5 V sous ~4,63 V) |
| **05:11:53** | Retour à la normale, 30 s plus tard |
| 05:12:05 | Sauvegarde terminée avec succès |

La sous-tension commence **34 s après le début de la sauvegarde** et se termine
**12 s avant sa fin**. Le SSD tire du courant à l'écriture, le rail flanche.

Ça éclaire la mesure du 3 septembre, où les resets UAS se déclenchaient sur des
**rafales d'écriture** et jamais au repos, sans mécanisme identifié. En voici un.

**Mais il faut résister à la conclusion facile, et deux faits s'y opposent :**

1. **Une seule sous-tension sur 7 jours**, alors que la sauvegarde tourne chaque
   nuit. Si le courant d'écriture suffisait à faire chuter le rail, ce serait
   quotidien. L'alimentation est donc *à la limite*, pas sous-dimensionnée.
2. **Aucune sous-tension pendant les 12 resets USB du 3 septembre.** Si la
   sous-tension causait les resets, elle aurait dû se déclencher là aussi.

Ce sont donc deux symptômes qui pointent tous deux vers « les rafales d'écriture
mettent ce montage en difficulté », sans qu'on puisse dire que l'un cause l'autre.

D'où la mesure plutôt que l'achat. Un compteur `history_stats`
(`sensor.raspberry_pi_sous_tensions_pi_7_jours`, type `count` sur 7 jours) et une
section « Alimentation du Pi » sur la vue Technique : compteur, graphe 7 jours
superposant la sous-tension et l'état du gestionnaire de sauvegarde, et journal à
la seconde. Si le compteur monte, l'alimentation ou le câble passent avant le
`usb-storage.quirks` — qui demande de toute façon un accès physique.

⚠️ Le compteur est plafonné par le `purge_keep_days` du recorder (13 jours
d'historique ici) : une fenêtre de 7 jours passe, 30 jours ne passerait pas.

### ⚠️ `sync_state` est une option par entité, jamais par adresse

Après la purge KNX il restait **348 avertissements xknx par jour** — mesure
confirmée : 464 lignes sur 32 h, sur exactement les 7 adresses prévues (les six
objets « mode de fonctionnement » des thermostats et `12/5/2`). Par défaut
`sync_state` vaut « expire 60 » : une relecture par heure et par adresse, deux
lignes de log par tentative sur une adresse qui ne répond pas.

Le remède annoncé était `sync_state: false`. Il était faux, deux fois :

1. **`sync_state` porte sur l'entité entière.** Sur un thermostat, elle couvre
   aussi `temperature_address` et les consignes — qui répondent parfaitement.
   Le poser à `false` aurait supprimé le bruit *et* la relecture des adresses
   saines.
2. **`false` n'est pas accepté sur la plateforme Climate**, ni sur Light, Cover,
   Switch, Number ou Text. La documentation renvoie vers la suppression de
   l'adresse d'état. Seuls binary_sensor, sensor, select, date, datetime, time,
   fan et weather l'acceptent.

D'où le panachage retenu :

| Entités | Valeur | Pourquoi |
|---|---|---|
| Les 6 thermostats | `sync_state: init` | Lecture au démarrage seulement : les adresses saines sont relues, la morte n'est réessayée qu'une fois par redémarrage au lieu de 24 fois par jour |
| `binary_sensor` « detection chan 1 » (`12/5/2`) | `sync_state: false` | Sa seule adresse est morte, rien à perdre — et `false` est accepté sur cette plateforme |

Vérifié après `knx.reload` : les six thermostats sont vivants et
`thermostat_salle_d_eau` a bien relu sa température (25,1 °C) et sa consigne au
rechargement. Le `init` fait exactement son travail.

### Le reste du passage

| Constat | Mesure | Décision |
|---|---|---|
| `recorder/import_statistics` sans `mean_type` ni `unit_class` | **1 376 lignes / 32 h**, première source de bruit | L'add-on MyElectricalData 0.13.4 importe les statistiques Enedis. **S'arrêtera de fonctionner en HA Core 2026.11.** À surveiller |
| `binary_sensor.interphone_motion` | **321 changements d'état / 24 h**, dont **zéro entre 07:00 et 18:30** | Faux positifs nocturnes : l'infrarouge de la Reolink attire les insectes. À traiter côté caméra (zone, sensibilité, détection *personne*) |
| Bail DHCP renouvelé toutes les 5 min | Redémarre `systemd-timesyncd` à chaque fois | Sans conséquence. Une réservation DHCP pour 192.168.0.95 y mettrait fin |

Et un faux positif à ne pas corriger : les 16 `bouclage ECS automatique: Already
running` **ne sont pas un bug**. L'automatisation se termine par un `delay` de
15 minutes qui sert de temporisation, et c'est `mode: single` qui la fait
respecter. L'avertissement, c'est la temporisation qui fonctionne.

Reste sain par ailleurs : Core 2026.9.0, `healthy: true`, `supported: true`,
configuration valide, **0 mise à jour en attente**, disque à 16 Go sur 457, base à
206 Mio, sauvegarde de la nuit réussie, **une seule ERROR** au journal système.

## 7 octobre 2026 — le compteur a tranché, et une erreur de lecture corrigée

Le 4 septembre on avait posé un compteur plutôt que d'acheter une alimentation, en
écrivant : *« si le compteur monte, c'est l'alimentation ou le câble qu'il faut changer,
avant de toucher au `usb-storage.quirks` »*. Le Pi a replanté, Mathias a basculé sur le
NAS puis est revenu sur le Pi. Relevé au retour :

Le compteur affichait **20**, contre **1** en septembre. Les 20 événements :

| Jour | Heures | Nombre |
|---|---|---:|
| 5 octobre | 22:26, 22:37 | 2 |
| 6 octobre | 04:46, 07:25, 07:51, 07:53, 12:00, 13:42, 14:32, 14:46, 15:30, 16:01, 20:08, 21:37, 21:51, 21:52 | **14** |
| 7 octobre | 04:19, 04:22, 04:50, 05:02 | 4 |

### ⚠️ L'erreur : « 20 par semaine » était faux, et trop optimiste

Premier jet de cette analyse : « rien du 30 septembre au 5 octobre, donc une date de
début nette le 5 octobre au soir — un composant qui lâche ». **C'était une mauvaise
lecture**, et Mathias l'a signalée en disant que le Pi était arrêté depuis deux ou trois
semaines.

Vérification faite, il avait raison : `sensor.cpu_temperature` ne porte **aucun
enregistrement** du 10 septembre au 5 octobre 18:00, alors que la rétention du recorder
couvre largement la fin de cette période. Le Pi était éteint. Le « rien » n'était pas une
absence d'événements, c'était une absence de machine.

Les sauvegardes quotidiennes le confirment par un autre chemin, et c'est joli : du
22 septembre au 5 octobre elles déclarent la version **2026.8.3** — c'est le conteneur du
NAS, resté figé sur l'image tirée le 31 août, exactement comme prévu quand on a écrit
qu'il ne fallait pas laisser le tag `:stable` sur une instance de secours. À partir du
6 octobre elles passent en **2026.9.0** : le Pi est de retour.

**Conséquence, et elle aggrave le diagnostic** :

| Lecture | Taux |
|---|---|
| ❌ 20 événements / 7 jours | ~3 par jour |
| ✅ 20 événements / **~41 h de fonctionnement réel** | **~12 par jour** |

Contre **1 sur une semaine entière** de fonctionnement continu en septembre. Ce n'est
donc pas un facteur 20 mais plutôt 80, et surtout : **le Pi sous-tensionne dès qu'il est
allumé**, pas à partir d'une date de bascule.

La seule conclusion de septembre qui tient est l'autre :

**Le lien avec la sauvegarde est rompu.** En septembre l'unique événement tombait pile
dans la fenêtre d'écriture de la sauvegarde nocturne. Désormais ça se déclenche à 4 h,
7 h, midi, 13 h, 14 h, 15 h, 16 h, 20 h, 21 h, 22 h. La rafale d'écriture n'est plus le
déclencheur — c'est permanent.

⚠️ **Piège à retenir** : un compteur `history_stats` compte sur une fenêtre de temps
*calendaire*, pas de temps de fonctionnement. Sur une machine qui tombe, son
dénominateur ment. La carte du tableau de bord porte maintenant cet avertissement.

La prudence de septembre (« à la limite, pas franchement sous-dimensionnée ») n'a donc
plus lieu d'être : **c'est le matériel d'alimentation**. La chaîne jusqu'au plantage est
cohérente de bout en bout — rail 5 V qui chute, reset du pont USB RTL9210, erreur d'E/S
sur le SSD de démarrage, Home Assistant qui tombe.

Correctif, par ordre d'efficacité : alimentation officielle 5,1 V / 3 A, câble USB-C
court et épais, et surtout **un hub USB alimenté pour le SSD** — seul moyen de sortir
complètement sa consommation du rail du Pi, et le seul correctif qui traite à la fois
les sous-tensions et les resets UAS.

La carte « Alimentation du Pi » de la vue Technique a été réécrite deux fois dans la
journée : son texte affirmait encore « une seule occurrence sur 7 jours », puis la
première correction reprenait le taux faux. Elle porte maintenant le taux ramené au temps
de fonctionnement, et l'avertissement sur la fenêtre du compteur.

### ✅ `sync_state: init` validé sur un mois

Le correctif KNX du 4 septembre tient. Sur la fenêtre de journal du 7 octobre, chacune
des 7 adresses mortes apparaît **exactement une fois**, toutes à 13:19:5x — c'est-à-dire
au redémarrage, et nulle part ailleurs.

| | Avant | Après |
|---|---:|---:|
| Avertissements xknx | **348 / jour** | **12 par redémarrage** |

### ⏳ MyElectricalData : l'échéance approche

Toujours **352 avertissements en 5 h** (`recorder/import_statistics` sans `mean_type` ni
`unit_class`), et l'add-on est toujours en **0.13.4** — aucune mise à jour depuis
septembre. L'échéance annoncée est **HA Core 2026.11**, soit la version suivante. Si rien
ne bouge d'ici là, la conso Enedis cessera de remonter.

### Nouveau depuis septembre

`waze_travel_time` produit **36 erreurs en 5 h** (« Unexpected error fetching
waze_travel_time data »), en continu et des deux côtés du redémarrage. Non diagnostiqué.

## 21 octobre 2026 — le bug UAS réglé par un déplacement de fiche

Soirée de dépannage qui a fini par résoudre, en dix secondes, ce que deux mois de
diagnostic n'avaient pas réglé.

### Le quirk appliqué puis rendu inutile

`usb-storage.quirks=0bda:9210:u` a été posé dans `cmdline.txt` (voir
`docs/procedure-quirk-uas.html`), avec l'identifiant relevé sur le matériel cette fois :
`USB\VID_0BDA&PID_9210`. Puis une panne de démarrage a conduit à tout remettre à plat,
et le disque a fini **branché sur un port USB 2.0** — un des deux ports noirs.

C'est ce dernier geste qui a tout changé :

```
usb 1-1.4: Product: RTL9210                            ← bus 1 = USB 2.0
usb-storage 1-1.4:1.0: USB Mass Storage device detected ← et non « scsi host0: uas »
```

**L'UAS a besoin des *streams* SuperSpeed de l'USB 3.0. Sur un port USB 2.0 il est
structurellement impossible.** Le port noir fait donc ce que faisait le quirk, en mieux :

| | `usb-storage.quirks` | Port USB 2.0 |
|---|---|---|
| Désactive UAS | ✅ | ✅ |
| Survit à une mise à jour de HAOS | ❌ à revérifier à chaque fois | ✅ rien à maintenir |
| Fichier à ne pas casser | ⚠️ `cmdline.txt` | ✅ aucun |

**Le coût est réel** — environ 35-40 Mo/s au lieu de 300+ — et assumé : sur une box
domotique dont les écritures sont petites et groupées (`commit_interval: 30`), la
stabilité vaut mieux qu'un débit dont on ne fait rien.

### Le test grandeur nature, passé

La mise à jour de Core qui a suivi est le plus gros volume d'écriture qu'une installation
subisse. C'est exactement ce qui avait fait tomber le Pi en septembre :

| | 2026.9.0 (septembre, UAS actif) | 2026.10.2 (ce soir, BOT) |
|---|---:|---:|
| Resets USB | **12 en 16 min** | **0** |
| Erreurs d'E/S | **14** | **0** |

### Le ventilateur ne refroidissait rien

Relevé pendant la panne : le ventilateur tournait **par à-coups**. C'est un modèle à
3 fils — rouge, noir, bleu — câblé selon le schéma officiel (broches 4, 6 et 8).

⚠️ Sur un ventilateur à **3 fils**, le troisième est un **retour tachymétrique**, pas une
commande : la vitesse ne se pilote pas, il tourne à fond dès qu'il a 5 V. Et la broche 8
est **GPIO 14, la sortie TX de la liaison série** — donc soit deux sorties se battent sur
le même fil, soit le ventilateur reçoit les messages de démarrage du noyau en guise de
signal. Dans les deux cas : **ne pas brancher le fil bleu.**

Mesure après débranchement complet :

| Date | Température | Ventilateur |
|---|---:|---|
| 7 octobre | 72,1 °C | branché |
| 11 octobre | 67-69 °C | branché |
| 15 octobre | 65,7 °C | branché |
| **21 octobre** | **52,1 °C** | **débranché** |

**20 °C de moins sans ventilateur qu'avec.** Un ventilateur qui cale ne déplace pas
d'air et fait obstacle à la convection. Réserve honnête : le boîtier était ouvert au
moment de la mesure, et le passage du disque en USB 2.0 soulage aussi le contrôleur
VL805 — la comparaison n'est donc pas isolée. À refaire boîtier fermé.

### La cause de fond, enfin nommée

Un **NVMe en boîtier USB** est parmi les charges les plus lourdes pour un Pi 4, dont les
quatre ports USB partagent **1,2 A, soit 6 W**. Un NVMe en charge en consomme 3 à 6 W à
lui seul. La chaleur du boîtier en était la mesure directe.

Ça invalide un conseil donné plus tôt dans ce dépôt : **changer l'alimentation n'aurait
rien réglé**, puisque le goulot n'est pas le bloc secteur mais la limite de courant des
ports, qui est fixe. Le remède reste **un hub USB alimenté** ou un boîtier à alimentation
séparée — à moins que le passage en USB 2.0 ne suffise, ce que le compteur de
sous-tensions dira dans les jours qui viennent.

### ⚠️ Pas de statistiques long terme sur `sensor.cpu_temperature`

Une courbe `statistics-graph` sur 30 jours a d'abord été posée sur la vue Technique. Elle
affichait **« Aucune statistique trouvée »**.

Cause : le capteur est un `command_line` défini dans `commandline.yaml` et **inchangé
depuis le 14 juin 2023**. Il n'a ni `device_class` ni `state_class` :

```yaml
sensor:
  name: CPU Temperature
  command: "cat /sys/class/thermal/thermal_zone0/temp"
  unit_of_measurement: "°C"
  value_template: "{{ value | multiply(0.001) | round(1) }}"
```

**Sans `state_class: measurement`, Home Assistant ne génère aucune statistique long terme
pour un capteur** — une carte `statistics-graph` n'a alors rien à afficher. L'absence de
`device_class: temperature` explique par ailleurs l'icône d'œil au lieu d'un thermomètre
sur la tuile.

La carte a donc été remplacée par un `history-graph` sur 336 h, qui lit directement le
recorder et fonctionne immédiatement — au prix de la fenêtre du `purge_keep_days`.

⚠️ **Les statistiques ne se rattrapent pas.** Ajouter `state_class` maintenant les ferait
démarrer à cette date, sans rien récupérer du passé : le palier à 70 °C de début octobre
est définitivement hors de portée d'une carte de statistiques.

### Un dernier relevé

L'horodatage des messages noyau dans le journal de l'hôte est **faux au démarrage** :
tout apparaît daté du 25 juin 2025. Le Pi 4 n'a pas d'horloge sauvegardée et repart sur
une date de repli avant que NTP corrige. Pour savoir de quel démarrage vient une ligne,
lire la version du noyau qu'elle contient (`Linux 6.18.39-haos-raspi`), pas son heure.

## 22 octobre 2026 — le vocabulaire des ouvrants, vérifié

Mathias a demandé les états des ouvrants Tydom en français. La demande a mis au jour une
condition d'alerte cassée depuis sa création, et une erreur de méthode que ce dépôt avait
déjà documentée deux fois sans que je l'évite pour autant.

### Le vocabulaire réel, menuiserie par menuiserie

Delta Dore ne publie pas l'énumération de son champ `openState` : ni sa documentation, ni
`tydom2mqtt`, ni l'intégration communautaire `hass-deltadore-tydom-component` ne la
décrivent. Elle a donc été établie par l'expérience — ouvrir puis refermer chaque type de
menuiserie, et relire le recorder :

| État | Signification | Vérifié sur |
|---|---|---|
| `LOCKED` | fermé et verrouillé | les 11 ouvrants |
| `UNLOCKED` | **coulissant ouvert** | baies vitrées gauche et droite |
| `OPEN_FRENCH` | battant ouvert | fenêtre salle de bain |
| `OPEN_HOPPER` | entrebâillé en oscillo-battant | fenêtre chambre d'amis |

**`UNLOCKED` n'est pas un simple déverrouillage.** Sur un coulissant, c'est l'état ouvert,
et il n'existe pas de variante `OPEN_SLIDING`. Le traiter comme anodin aurait sorti les
deux baies vitrées du périmètre des alertes — l'erreur a été évitée de justesse, après que
Mathias ait signalé que les baies se comportaient peut-être autrement que les fenêtres.

### La condition d'alerte ne couvrait que 2 ouvrants sur 11

`dashboards/maison.yaml` filtrait sur `UNLOCKED` **et `OPENED`**, à deux endroits : la
visibilité de la section « Attention » de la vue Maison, et la carte `entity-filter`
« Ouvrants ouverts ». `OPENED` n'existe pas dans le vocabulaire de la box. Les neuf
fenêtres, qui remontent `OPEN_FRENCH` ou `OPEN_HOPPER`, n'ont donc jamais déclenché ni
l'une ni l'autre. Seules les deux baies, sur `UNLOCKED`, fonctionnaient.

Le bug venait d'une hypothèse écrite dans ce README comme un « point de méthode » acquis,
sans avoir été vérifiée une seule fois contre l'historique.

À noter : **les automatisations d'alarme n'étaient pas concernées.** `Alarme Nuit` et
`Alarme Vacances` se déclenchent sur les détecteurs de mouvement KNX (`capteur_cuisine`,
`capteur_salon_piano`, `capteur_patio`, `capteur_garage`), pas sur les ouvrants Tydom.
C'était de l'affichage cassé, pas de la sécurité.

### Onze capteurs modèles et une macro

La traduction d'un état arbitraire n'a aucun équivalent natif dans Home Assistant : il faut
des capteurs modèles. Onze ont été ajoutés au bloc `template:` de
`config/configuration.yaml`, un par ouvrant, nommés `<lieu> état`.

La correspondance est définie **une seule fois**, dans `config/custom_templates/tydom.jinja` :

```jinja
LOCKED                        → Fermé
UNLOCKED                      → Ouvert
OPEN_HOPPER                   → Oscillo-battant
tout ce qui commence par OPEN → Ouvert
unknown / unavailable         → Inconnu
reste                         → la valeur brute, telle quelle
```

Deux choix délibérés :

**Le filtre par préfixe plutôt qu'une énumération.** `OPEN_FRENCH`, `OPEN_SLIDING`,
`OPENED` — peu importe ce que Delta Dore ajoute, tout tombe sur « Ouvert » sans qu'il
faille deviner la liste. Seul `OPEN_HOPPER` garde sa nuance, puisque c'est la distinction
demandée.

**Un état inconnu est renvoyé tel quel**, et non rangé de force dans une catégorie. Il
s'affichera en clair sur le tableau de bord au lieu de se fondre dans « Ouvert ».

Le mapping a été prouvé sur neuf entrées avant livraison, y compris celles qu'on n'a jamais
observées, via `ha_eval_template` — les crochets servaient à vérifier l'absence d'espace
parasite :

```
LOCKED -> [Fermé]            UNLOCKED     -> [Ouvert]
OPEN_FRENCH -> [Ouvert]      OPENED       -> [Ouvert]
OPEN_HOPPER -> [Oscillo-battant]  OPEN_SLIDING -> [Ouvert]
unknown -> [Inconnu]         unavailable  -> [Inconnu]
BIDULE_INCONNU -> [BIDULE_INCONNU]
```

**Pourquoi du YAML et pas des aides d'interface.** Les bonnes pratiques recommandent le
flux de configuration plutôt que `template:` en YAML, sauf — entre autres — pour définir
plusieurs entités dans un même bloc, ce qui est le cas ici. Et surtout : une aide créée par
l'interface vit dans `.storage`, donc hors de ce dépôt. Tout l'intérêt de ce projet est que
la logique soit lisible dans un diff. L'outil d'édition YAML prévoit lui-même l'exception
« configuration délibérément gérée en YAML, par exemple suivie par git ».

Contrepartie assumée : ces onze capteurs ne sont pas modifiables depuis l'interface. Ils
portent un `unique_id`, donc leur nom affiché reste changeable.

### Ce qui a été repointé

Les capteurs bruts `sensor.openstate_tydom_*` restent en place et continuent d'alimenter
les capteurs français. Plus aucune carte ne les affiche :

| Tableau | Emplacement | Changement |
|---|---|---|
| Maison | visibilité section « Attention » | 11 conditions → capteurs français, états `Ouvert` / `Oscillo-battant` |
| Maison | carte `entity-filter` « Ouvrants ouverts » | 11 entités + la condition |
| Maison | vue Sécurité, carte « Ouvrants » | 11 entités |
| Aperçu | carte historique « fenêtres et détecteurs » | 10 entités |
| Aperçu | carte `entities` des ouvrants | 11 entités |

Conséquence à anticiper : **la section « Attention » va désormais s'allumer pour de vrai**
quand une fenêtre est ouverte. Elle ne le faisait pas pour neuf ouvrants sur onze.

La carte historique perd l'antériorité des ouvrants : les capteurs français n'ont pas
d'historique avant 11 h 27 ce jour-là. La carte affiche 72 h, elle se remplit donc d'
elle-même en trois jours.

### ⚠️ Lire une absence de données comme une absence de phénomène

**Troisième occurrence du même piège dans ce projet.** `UNLOCKED` était absent de 17 jours
de recorder et de 11 capteurs. J'en ai conclu — et écrit à Mathias — qu'il « n'existe pas
dans le vocabulaire de la box ». Il existe : personne n'avait simplement ouvert une baie
depuis le 5 octobre.

Les deux précédentes :

- **7 octobre** — un trou de `sensor.cpu_temperature` lu comme un Pi en bonne santé, alors
  que la machine était plantée depuis trois semaines. Un `history_stats` compte sur une
  fenêtre de calendrier, pas de temps de fonctionnement.
- **22 octobre au matin** — des valeurs MQTT *retained* rejouées au démarrage, prises pour
  des mesures fraîches. Seul `last_reported` prouve la fraîcheur, jamais la plausibilité de
  la valeur.

Le réflexe à appliquer : avant d'écrire qu'une valeur n'existe pas, vérifier que la fenêtre
d'observation contenait une occasion de la produire.

### Restes identifiés, non traités

- `sensor.openstate_tydom_baie_vitree` est sur `unknown` depuis toujours et n'est référencé
  nulle part — entité orpheline d'une ancienne configuration, sans jumeau français.
- La carte historique de l'Aperçu ne liste que 10 ouvrants sur 11 : `Fenêtre chambre
  parentale` y manque, et manquait déjà avant. Composition laissée telle quelle.
- `state_color: true` sur les cartes `entities` ne colore pas un capteur textuel. Une macro
  d'icône (`mdi:window-open-variant` / `mdi:window-closed-variant`) réglerait la lisibilité
  d'un coup d'œil ; hors du périmètre demandé.

## 22 octobre 2026 — la latence des caméras : le flux principal au lieu du sous-flux

Mathias a signalé que les caméras de la vue Sécurité avaient « une grosse latence »,
alors que l'onglet Camera du tableau d'origine est fluide. Il a demandé de reprendre les
réglages et les types de cartes qui marchent là-bas. Comparaison des deux vues :

| | Tableau d'origine (fluide) | Vue Sécurité (laggy) |
|---|---|---|
| Interphone | `camera.interphone_sub` | **`camera.interphone_main`** |
| `camera_view` | `live` | **`auto`** |
| `fit_mode` | `cover` | absent |

Deux erreurs cumulées, toutes les deux de mon fait.

**Le mauvais flux.** Les noms conviviaux sont en français et trompeurs si on ne connaît
pas la convention : `camera.interphone_main` s'appelle **« Interphone Net »** et
`camera.interphone_sub` **« Interphone Fluide »**. C'est le vocabulaire Reolink traduit —
*clear* / *fluent* — autrement dit flux principal haute résolution contre sous-flux basse
résolution. En choisissant `_main`, j'ai cru prendre « la vraie caméra » ; j'ai pris celle
que le Raspberry Pi a le plus de mal à servir.

**Le mauvais mode d'affichage.** `camera_view: auto` affiche une **image fixe rafraîchie
par minuterie** : ce qu'on voit peut avoir une dizaine de secondes. `camera_view: live`
ouvre un flux continu. Sur un sous-flux basse résolution, `live` démarre vite — c'est
exactement le réglage du tableau d'origine.

Réglages désormais alignés sur l'original : `interphone_sub` + `live` + `fit_mode: cover`
pour l'interphone, `live` + `fit_mode: cover` pour l'entrée du garage. Les noms affichés
(`show_name: true` avec un `name`) sont conservés : la vue Sécurité empile trois caméras
sous un seul titre de section, l'étiquette aide à les distinguer. Sans effet sur la latence.

**`camera.127_0_0_1` reste en `auto`, et ce n'est pas un oubli.** Ses
`supported_features` valent **0** — pas de capacité de flux. C'est la dernière capture
prise par l'automatisation `Prendre une photo en cas de mouvement ou sonnette`, donc une
image fixe par nature. `live` n'y est pas une option. Les trois autres caméras valent `2`,
soit `CameraEntityFeature.STREAM`.

### ⚠️ Une anomalie dans le tableau d'origine, non corrigée

La carte « entrée garage » de l'onglet Camera porte :

```yaml
type: picture-entity
entity: camera.entree_garage_fluide
camera_image: camera.interphone_sub    # ← ne désigne pas la même caméra
camera_view: live
```

Sur une carte `picture-entity`, c'est `camera_image` qui désigne la caméra affichée quand
il est renseigné ; `entity` ne sert alors qu'à l'état. Cette carte montre donc
vraisemblablement **l'interphone** et non l'entrée du garage. Ça ressemble à un
copier-coller. Non touché : c'est le tableau historique, et un coup d'œil suffit à
confirmer ou à démentir — si les deux cartes de cet onglet affichent la même image, c'est
ça.

### La leçon

Deux entités qui ne diffèrent que par un suffixe technique, avec des noms affichés en
français qui n'en portent pas la trace évidente, méritent une vérification avant d'être
câblées dans une carte. Le tableau d'origine contenait déjà la réponse : il suffisait de
le lire avant d'en écrire un nouveau.

## 22 octobre 2026 — le forçage du sèche-serviettes, et deux conclusions fausses

Mathias a demandé un regard sur l'automatisation « forçage salle d'eau », dont l'objet est de
sécher les serviettes après une douche. Elle avait quatre choses à redire, dont deux que j'ai
inventées.

### Ce que j'ai affirmé à tort

**« Pendant 2 h de forçage, rien n'a chauffé ».** Faux. Je m'étais appuyé sur
`binary_sensor.actionneur_de_chauffe_salle_d_eau` (`7/1/2`) et
`sensor.pourcentage_de_chauffe_salle_d_eau` (`7/1/3`), restés à l'arrêt et à 0 % pendant tout le
forçage, pour conclure que rien ne chauffait.

Mathias a corrigé : **`7/1/2` est la demande envoyée à l'actionneur, pas sa sortie.** Une
temporisation anti-battement est réglée dans l'actionneur KNX pour éviter les commutations trop
rapprochées, et c'est `12/4/1` qui porte l'état réel de chauffe. Ses données le démontrent
proprement :

| `7/1/2` (demande) | `12/4/1` (sortie réelle) |
|---|---|
| on 08:34:23 | on 08:35:23 |
| off 08:40:23 | off 08:41:23 |
| on 08:49:23 | on 08:50:23 |
| off 08:53:15 | off 08:54:15 |
| **on 09:04:23 → off 09:04:53** | **rien** |

Exactement 60 s de retard sur chaque front, et une impulsion de demande de 30 s qui n'atteint
jamais la sortie : la temporisation filtre sous mes yeux. Et la température de la pièce est montée
de **22,2 à 22,9 °C**, en continuant de grimper 22 minutes après la coupure du forçage — l'inertie
d'une masse chauffée deux heures. Le creux de 25 minutes au début, qui m'avait égaré, c'était le
radiateur qui montait en température avant que la pièce suive.

**Et le correctif que je proposais aurait été une faute.** Je voulais donner
`state_address: "12/4/1"` au commutateur de forçage `12/4/0`, croyant que `12/4/1` était l'accusé
de réception du forçage. Comme c'est la sortie de chauffe, la tuile « Forçage salle d'eau » se
serait affichée allumée à chaque cycle de chauffe nocturne. Le commutateur reste donc optimiste
par construction, comme les autres interrupteurs KNX sans `state_address` déjà recensés plus haut.

Dans la même erreur, j'avais signalé un faux bug : les lignes « Salle d'eau » et « Mur chauffant »
de la carte des vannes affichent `12/4/1` et `12/4/2` là où les quatre chambres affichent
`17/3/x`. Ce n'est pas une incohérence — ces deux lignes montrent la sortie réelle, c'est le
signal le plus juste.

### Pourquoi elle était désactivée — la vraie raison

Elle l'était depuis le 5 octobre, volontairement, et aucun de mes griefs n'était la cause :
**la simulation de présence peut allumer `light.salle_d_eau` alors que personne n'est là**, ce qui
lançait une heure de sèche-serviettes pour rien. Le défaut n'était pas dans le minutage mais dans
l'absence de garde-fou.

D'où la condition ajoutée, et la raison pour laquelle il ne faut pas la retirer :

```yaml
- condition: state
  entity_id: switch.presence_simulation
  state: "off"
```

`switch.presence_simulation` expose aussi un attribut `active_entities` listant les entités
qu'elle pilote à l'instant : une garde plus fine est possible si le besoin apparaît, mais pendant
la simulation on est absent, donc on ne veut jamais le sèche-serviettes.

### Le défaut réel : un `for:` ne survit pas à un redémarrage

L'arrêt reposait sur un déclencheur « lumière éteinte **depuis 1 h** ». La référence des bonnes
pratiques est explicite : *« On restart the state is restored but `last_changed` is re-stamped to
start-up time, so the duration clock restarts from zero »*, et *« a long `for:` is unreliable as a
safety backstop »*.

Mesuré ce jour-là :

| | |
|---|---|
| Lumière éteinte | 11:16:16 |
| Arrêt attendu | 12:16:16 |
| Redémarrage de HA | 11:49:52 — remise à zéro du `last_changed` |
| Arrêt réel | **13:00:00**, soit **44 minutes de trop** |

Dans une pièce déjà à 22,2 °C, avec un thermostat qui ne demandait rien. Et il y a eu six
redémarrages la veille au soir. L'ancienne description affirmait pourtant qu'« un redémarrage de HA
ne peut plus laisser le chauffage allumé indéfiniment » : vrai pour *indéfiniment*, faux pour
*inchangé*.

**Correctif : l'heure est désormais tenue par `timer.sechage_salle_d_eau`, avec `restore: true`.**
Un minuteur reprend où il en était après un redémarrage. La référence propose aussi un
`input_datetime` horodaté ; le minuteur a été préféré parce qu'il est fait pour un décompte borné et
qu'il fournit un déclencheur natif `timer.finished` — déclencheur dédié depuis 2026.5, à préférer à
l'ancienne forme `event_type: timer.finished`.

### La forme retenue

Spécification de Mathias : chauffe pendant la douche, puis 1 h après.

| Déclencheur | Condition | Action |
|---|---|---|
| Lumière allumée depuis 2 min | simulation à l'arrêt | forçage en marche |
| Lumière rallumée | simulation à l'arrêt, séchage en cours | annule le minuteur |
| Lumière éteinte | forçage en marche | démarre le minuteur (1 h) |
| `timer.finished` | — | coupe le forçage |
| Démarrage de HA + toutes les 15 min | forçage actif, minuteur à l'arrêt, lumière éteinte depuis 2 min | coupe le forçage |

`mode: queued` (`max: 5`) remplace `single` : avec six déclencheurs dont un rattrapage au quart
d'heure, `single` peut faire tomber un événement arrivé pendant qu'un autre s'exécute.

Le rattrapage couvre deux cas que le minuteur seul ne couvre pas : une échéance tombée pendant que
HA était arrêté, et un événement d'extinction manqué sur le bus KNX.

L'alias passe de « Forçage chauffage salle **de bain** » à « salle **d'eau** » — tout son contenu
désignait la salle d'eau depuis l'origine. **L'`entity_id` reste
`automation.forcage_chauffage_salle_de_bain`** : le renommer ne casserait rien d'identifié dans ce
dépôt, mais ne vaut pas le risque pour une question de cosmétique.

### Le seuil de 8 minutes, ajouté dans un second temps

Proposé puis demandé par Mathias : l'heure de séchage n'est accordée que si la lumière est restée
allumée **au moins 8 minutes**, pour qu'un passage de deux minutes aux toilettes n'offre pas une
heure de sèche-serviettes. Le seuil porte sur le séchage seulement, pas sur l'allumage — une douche
courte bénéficie quand même d'une pièce chaude.

Trois conséquences qui ne sautaient pas aux yeux :

**Le déclencheur « lumière rallumée → annule le minuteur » a dû disparaître.** Avec le seuil, un
aller-retour de 30 s pendant le séchage ferait échouer le test de durée à l'extinction suivante et
**couperait le séchage en cours**. Le minuteur continue donc de tourner pendant un passage bref ;
une vraie seconde douche redémarre l'heure à son extinction.

**La branche « fin du séchage » exige désormais lumière éteinte.** Sans ça, un minuteur arrivant à
échéance pendant qu'on se douche couperait le chauffage sous la douche.

**Une branche de coupure immédiate** a été ajoutée pour l'extinction après moins de 8 min, plutôt
que de laisser le rattrapage au quart d'heure s'en charger jusqu'à 15 minutes plus tard. L'ordre des
branches d'un `choose` fait le travail : la branche « ≥ 8 min » est évaluée d'abord, donc la suivante
n'a pas besoin de nier le test.

### ⚠️ Un avertissement de bonne pratique assumé

Le vérificateur a signalé la condition templatée (« Template detected in condition — if this maps to
a native option, use that instead »). Elle est maintenue, et voici le raisonnement, pour que
personne ne la « corrige » sans le relire.

La voie native serait un `binary_sensor` modèle sur `{{ is_state('light.salle_d_eau','on') }}` avec
`delay_on: 8 min`, lu par une `condition: state` — c'est exactement le motif que recommande
`helper-selection.md` pour sortir une durée d'une condition. Mais au moment où la lumière s'éteint,
ce capteur retombe à `off` **sur le même changement d'état** que celui qui déclenche
l'automatisation, et rien ne garantit l'ordre d'évaluation. Il faudrait lui ajouter un `delay_off`
de quelques secondes pour esquiver la course.

Le template, lui, lit `trigger.from_state` et `trigger.to_state` — deux instantanés capturés avec le
déclencheur, donc insensibles à cette course par construction. Un garde-fou explicite valait mieux
qu'un délai réglé au doigt mouillé. Il porte le garde recommandé par la référence
(`trigger.platform == 'state' and trigger.from_state is not none`), sans quoi le rattrapage au quart
d'heure le ferait lever une `UndefinedError`.

Vérifié à `ha_eval_template` avant livraison, sur cinq cas :

```
douche de 33 min                  -> True
passage de 1m42                   -> False
pile 8 min                        -> True
7 min 59 s                        -> False
rattrapage (pas un trigger state) -> False
```

## 22 octobre 2026 — l'alarme : deux trous, dont un de mon fait

Mathias a demandé s'il existait mieux que ses cinq automatisations d'alarme. Réponse : non, et sa
structure est bonne. Mais les lire a révélé deux défauts.

### Pourquoi cinq automatisations, ce n'est pas trop

Elles forment deux couches nettement séparées :

| Couche | Automatisations | Rôle |
|---|---|---|
| Entrée | détection nuit, détection vacances | capteurs → machine à états du panneau |
| Sortie | pré-alerte, déclenchement, extinction sirène | machine à états → effets physiques |

Le panneau `manual` tient la machine à états lui-même (`arming_time: 30`, `delay_time: 60`,
`trigger_time: 600`) ; les automatisations ne font que traduire dans un sens puis dans l'autre.
Avec cette plateforme, cinq est proche du plancher.

**Fusionner les deux détections a été envisagé et écarté.** Elles ne diffèrent que par le mode armé,
le jeu de capteurs (patio exclu en vacances) et le libellé. Les fusionner demanderait un template sur
le chemin critique d'un système d'alarme pour économiser un fichier.

**Alarmo (HACS) a été proposé et refusé par Mathias.** C'était la seule vraie alternative : il
absorbe toute la couche d'entrée dans sa propre interface. Trois contreparties pesaient contre :
c'est une intégration tierce qu'une mise à jour de HA peut casser, la migration touche la tuile, les
badges, les quatre booléens `critique_*` et `script.alerte_famille`, et surtout **sa configuration
vit dans `.storage`, donc hors de ce dépôt** — l'alarme cesserait d'être documentée dans git.

### ⚠️ La sirène ne s'arrêtait jamais toute seule

`automation.eteindre_la_sirene` déclenchait sur `from: triggered` **et `to: disarmed`**. Or la
documentation du panneau `manual` est explicite : *« When `trigger_time` expires, the alarm returns
to the state it was in before triggering »*, sauf si `disarm_after_trigger` est vrai — et il n'est
pas réglé dans `configuration.yaml`.

Donc après les 600 s de `trigger_time`, le panneau passe `triggered → armed_night` ou
`armed_vacation`, jamais `disarmed`. **La transition attendue n'arrivait pas, et la sirène
extérieure tournait jusqu'à un désarmement manuel** — précisément le scénario où personne n'est à la
maison.

Corrigé en listant les cinq états d'arrivée dans `to:`. Les états sont énumérés plutôt que `to:`
omis : ça reste entièrement natif, et ça exclut un passage par `unavailable` au redémarrage de HA,
qui couperait la sirène en pleine alarme sans la rallumer.

**Les deux scripts de clignotement n'avaient pas ce défaut** : ils bouclent sur
`while: alarme = triggered` (resp. `pending`) et s'arrêtent d'eux-mêmes. Vérifié avant de conclure.

### ⚠️ `armed_home` et `armed_away` n'armaient rien — et c'est moi qui ai ouvert le trou

Aucune automatisation, script, scène ni aide ne référence ces deux états. Le panneau pouvait s'y
armer, décompter ses 30 secondes, et aucun capteur ne l'aurait jamais déclenché.

Le tableau d'origine était juste : sa carte `custom:mushroom-alarm-control-panel-card` n'expose que
`armed_night` et `armed_vacation`, les deux modes qui fonctionnent. **La tuile construite pour la
vue Sécurité en proposait cinq**, sans vérification que la logique existait. Deux modes décoratifs
sur un système d'alarme.

Ramenée à `disarmed` / `armed_night` / `armed_vacation`, avec un commentaire dans
`dashboards/maison.yaml` interdisant de les rajouter sans écrire la détection correspondante.

### La leçon

Reprendre un tableau de bord existant, c'est aussi reprendre les décisions qu'il encode. Les deux
modes absents de la carte Mushroom n'étaient pas un oubli : c'était la seule documentation du fait
que la détection n'existait pas. Je l'ai élargie sans me demander pourquoi elle était étroite —
la même erreur que pour les caméras, où le tableau d'origine portait déjà la réponse.

### Restes identifiés, non traités

- `binary_sensor.capteur_porche` et `binary_sensor.capteur_couloir_etage` sont affichés dans la vue
  Sécurité mais ne déclenchent aucune détection. Probablement volontaire (le facteur sur le porche,
  les allers-retours nocturnes dans le couloir), à confirmer.
- Aucun blocage d'armement si un ouvrant est ouvert. Devenu facile depuis que les 11 capteurs
  d'ouvrants parlent français : une condition sur `Ouvert` / `Oscillo-battant` suffirait.

## 22 octobre 2026 — un réglage général pour les six thermostats

Mathias voulait pouvoir réaligner les six thermostats d'un seul geste. Au moment de la demande
les consignes avaient effectivement dérivé :

| Thermostat | entity_id | Temp. | Consigne | Mode |
|---|---|---|---|---|
| Salle d'eau | `climate.thermostat_salle_d_eau` | 23,3 | **21** | standby |
| Salle de bain | `climate.thermostat_salle_de_bain` | 21,7 | **21** | standby |
| Chambre parents | **`climate.thermostat`** | 21,6 | **20** | standby |
| Chambre Margaux | `climate.thermostat_chambre_margaux` | 21,7 | **20** | standby |
| Chambre Auguste | `climate.thermostat_chambre_auguste` | 20,6 | **21** | standby |
| Chambre amis | `climate.thermostat_chambre_amis` | 20,5 | **20** | standby |

(La chambre des parents porte l'entity_id `climate.thermostat` tout court — résidu de la première
configuration, conservé pour ne rien casser.)

### Pas d'aide « groupe » possible

Vérifié : l'aide `group` couvre `binary_sensor`, `button`, `cover`, `event`, `fan`, `light`,
`lock`, `media_player`, `notify`, `sensor`, `switch` et `valve`. **Pas `climate`.**

### Ce que le câblage KNX impose

Les six thermostats sont configurés à l'identique, et aucun n'expose d'adresse de consigne
**absolue** en écriture :

```yaml
temperature_address: "7/1/0"              # température ambiante, lecture
setpoint_shift_address: "7/0/4"           # ← le SEUL levier en écriture
target_temperature_state_address: "7/1/1" # consigne effective, lecture seule
operation_mode_address: "7/0/5"           # le mode (comfort / standby / economy…)
```

`climate.set_temperature` écrit donc un **décalage** par rapport à la consigne de base du mode en
cours, base définie dans ETS — pas une consigne absolue. **Conséquence à vérifier dans ETS :** ce
décalage n'est en général pas mémorisé par mode, donc réaligner les consignes en `standby` décale
aussi le confort d'autant.

### La solution : une entité `climate` modèle, pure façade

Un seul objet plutôt qu'un empilement `input_number` + `input_button` + automatisation :
`climate.chauffage_general`, construite avec la plateforme `template → climate` (2026.10+).

- **`current_temperature`** = moyenne des six températures ambiantes.
- **`target_temperature`** = moyenne des six consignes. Choix délibéré plutôt qu'une valeur
  « dernière commandée » : **le cadran révèle la dérive.** Au moment de l'installation il affichait
  20,7 — soit trois pièces à 21 et trois à 20. Aligné, il affiche un nombre rond.
- **`set_temperature`** relaie vers les six, **`set_preset_mode`** aussi : un seul geste pour tout
  passer en `comfort` ou `standby`.
- **`preset_mode` laissé en mode optimiste** (pas de template) : avec six valeurs qui peuvent
  diverger, afficher une majorité serait un mensonge, et un septième libellé « mixte » serait
  sélectionnable alors qu'il ne veut rien dire à l'écriture.

**Propriété rassurante : ce n'est qu'une façade.** Elle ne pilote rien par elle-même, elle appelle
les actions des six thermostats réels. Si elle casse, les six tuiles continuent de fonctionner.
C'est ce qui a rendu acceptable l'usage d'une plateforme sortie le mois même.

### Pourquoi une macro et pas une aide `min_max`

Les bonnes pratiques disent : moyenne de plusieurs capteurs → aide `min_max`, pas de template. Mais
`min_max` n'accepte que des membres `sensor`, `number` et `input_number` — **pas des attributs
d'entités `climate`**. La voie native aurait demandé 12 capteurs modèles d'extraction plus 2 aides,
soit 14 objets. La moyenne est donc définie une seule fois dans
`config/custom_templates/chauffage.jinja`, appelée deux fois.

### Deux pièges rencontrés en chemin

**`preset_modes` doit être un template, pas une liste YAML.** La documentation officielle du
template climate montre pourtant une liste dans son exemple complet ; c'est sa table de référence
qui a raison. HA rejette le bloc entier avec :

```
Invalid config for 'template': template value should be a string for dictionary value
'climate->0->preset_modes', got ['standby', 'economy', …]
```

À noter : HA n'écarte que l'entrée fautive, les onze capteurs d'ouvrants du même bloc `template:`
ont continué de tourner. Vérifié avant de corriger.

**Sans `hvac_mode`, l'état de l'entité est `unknown`.** Le `hvac_mode` est optimiste par défaut :
tant que personne n'a tapé sur « chauffage », la carte s'affiche mal — et ça recommence à chaque
redémarrage. Figé par `hvac_mode: "{{ 'heat' }}"`, puisque les thermostats KNX n'ont de toute façon
que ce mode.

### Note de méthode : l'aperçu de `ha_config_set_yaml`

`configuration.yaml` ne peut être modifié que par clé entière — `ha_write_file` ne l'autorise pas
(seuls `www`, `themes`, `custom_templates`, `dashboards`, `knx.yaml`, `commandline.yaml`). Il a donc
fallu réécrire toute la clé `template`, 133 lignes. **Le premier essai contenait une faute de ma
part** : un `"\n"` du Jinja sur-échappé, qui serait devenu `"\\n"` et aurait cassé le capteur
« toutes ». L'aperçu en deux temps l'a attrapé et rien n'a été écrit. Ne jamais contourner ce filet
sur un fichier de cette taille.

## 23 octobre 2026 — MyElectricalData : où ça en est, et ce qui casse en novembre

Mathias demandait où en était l'intégration Enedis. Réponse courte : **elle marche, et elle a une
date de péremption**.

L'add-on `myelectricaldata` installé est en **0.13.4**. En amont, la dernière publication du projet
date du **14 janvier 2025** — vingt-et-un mois sans release.

### Comment il alimente le tableau Énergie

Par **une seule statistique externe**, `myelectricaldata:<PDL>_base_consumption`. Il n'y a aucune
entité `sensor.` derrière : la case « Réseau électrique » du tableau Énergie lit directement cette
statistique. Rien d'autre dans la maison n'en dépend, et rien d'autre ne peut la remplacer sans
reconfigurer le tableau Énergie.

Volume de bruit au journal : **528 avertissements en 8 h**. Pénible, pas bloquant.

### ⚠️ Ce qui casse en 2026.11

Depuis **Core 2026.11**, `recorder/import_statistics` exige deux champs supplémentaires,
`unit_class` et `mean_type`. L'add-on 0.13.4 ne les envoie pas : l'import sera **rejeté**, et le
tableau Énergie n'aura plus de données Enedis. 2026.11 est attendue vers le **mercredi 4 novembre
2026** (cadence du premier mercredi du mois).

État en amont :

| | |
|---|---|
| Issue **#623** | ouverte depuis le **25 avril 2026**, toujours ouverte |
| PR **#635** | **complète** mais non fusionnée, sans activité depuis le **3 septembre 2026** |
| Add-on successeur `myelectricaldata_new` | **inutilisable** : aucune release, aucune image publiée |

### Décision

**Ne pas monter en Core 2026.11** tant que #635 n'est pas fusionnée ou qu'une solution de rechange
n'est pas en place. La version actuelle (2026.10.2) n'a aucun problème avec cet add-on.

Une bonne nouvelle quand même : **une statistique externe, elle, peut être rétro-alimentée.**
`recorder/import_statistics` accepte des points dans le passé — contrairement aux statistiques
dérivées d'un `sensor`, qui ne se reconstruisent pas. Un trou de quelques semaines pourra donc être
rebouché après coup si la passerelle myelectricaldata.fr a conservé les données. *(Je me suis trompé
sur ce point plus tôt dans la conversation en affirmant qu'aucune statistique ne se rétro-alimente :
c'est vrai pour les statistiques de capteurs, faux pour les statistiques externes.)*

> Le PDL n'est pas écrit dans ce dépôt : il est **public**. Il se trouve dans les options de l'add-on,
> dans l'interface de Home Assistant.

Je n'ai **rien publié** sur le dépôt du projet. Relancer la PR #635 est possible, mais c'est un dépôt
tiers et il faudrait décider sous quel compte — à voir avec Mathias.

## 23–24 octobre 2026 — la chute de 14 minutes : la cause cernée, et trois instruments posés

Le vendredi 23 octobre au matin, le Pi est tombé et est reparti seul. Personne ne s'en est aperçu
avant le soir.

| Heure (Paris) | Fait |
|---|---|
| **07:44:24** | Dernier battement de cœur avant la chute — `sensor.cpu_temperature` à 59,4 °C, rien d'anormal |
| *14 minutes de silence* | |
| **07:58:21** | Démarrage de l'hôte (ligne du superviseur) |
| **07:59:31** | Core `RUNNING` |

La base sqlite porte la trace d'un **arrêt non propre** : ce n'est pas un redémarrage commandé.

### Ce qui est écarté

- **Pas le redémarrage programmé.** `automation.reboot_ha_host` tourne le **mercredi à 3 h**. Le 23
  était un vendredi, à 7 h 44.
- **Pas Mathias.** Il n'a rien touché.
- **Pas une sous-tension.** `binary_sensor.rpi_power_status` : **0 événement sur 7 jours**. Le capteur
  n'est pas mort — dernière remontée à 22:18:26 le même soir — donc ce zéro est fiable. *(J'ai
  d'abord cru le capteur silencieux parce que mes recherches ne le trouvaient pas ; il va très bien.)*
- **Pas un plantage logiciel visible.** Le `fault_log` du superviseur est vide.

### ⚠️ Le journal de HA OS est volatile — un redémarrage efface sa propre cause

La plus ancienne ligne encore disponible dans le journal de l'hôte est **07:59:32**, soit *après* le
redémarrage. Les minutes qui l'ont précédé n'existent plus. C'est une propriété du journal, pas un
réglage : il vit en mémoire et repart de zéro à chaque boot.

**Conséquence de méthode : sur cette machine, une panne non instrumentée à l'avance est une panne
définitivement inexplicable.** D'où ce qui suit.

### Ce n'était PAS une coupure de secteur — tranché le 24 octobre

J'avais retenu, faute de preuve, l'hypothèse d'une **coupure de secteur d'environ 14 minutes** :
un Pi figé reste figé, son chien de garde le relance en ~15 s, et une absence d'alimentation
expliquait exactement la durée observée. Mathias a exporté le journal système du NAS. **Il
l'infirme.**

Le journal DSM couvre le 18 mars 2024 → 23 octobre 2026, 8 344 lignes. Ce qui le rend décisif :
**il enregistre chaque démarrage** — 154 « System started to boot up », dont 26 suivis de « System
booted up from an improper shutdown ». Un NAS qui perd le courant le dit, et le dit encore au
redémarrage suivant.

| | |
|---|---|
| Dernier démarrage du NAS avant la panne | **21 octobre 23:18:12** (après la mise à jour DSM 7.3.2-86009 Update 5) |
| Démarrage le 23 octobre | **aucun** |
| Lignes du 23 octobre entre 05:38:19 et 20:42:58 | **aucune** |
| Mentions d'onduleur / batterie en 2 ans et demi | **zéro** — le NAS est sur le secteur nu |

**Le NAS, branché sur le même réseau électrique et sans onduleur, n'a pas bronché pendant que le Pi
était absent 14 minutes.** Il n'y a donc pas eu de coupure générale.

> Réserve honnête : ceci suppose que le Pi et le NAS sont sur le même circuit. S'ils sont sur deux
> disjoncteurs différents, une coupure partielle reste possible — à vérifier en regardant où chacun
> est branché.

Et la courbe de charge Enedis devient **inutile** : elle mesure la maison entière, dont on sait
maintenant qu'elle n'a pas été coupée. Une course en moins.

### Donc : l'alimentation du Pi lui-même

Ce qui reste doit expliquer **14 minutes d'absence suivies d'un démarrage propre**, sans intervention
humaine :

- **Un plantage logiciel est exclu.** Un Pi figé ne se relance pas tout seul un quart d'heure plus
  tard. Le chien de garde matériel, armé par HA OS, le relancerait en ~15 s — on aurait un démarrage
  à 07:45, pas à 07:58. Et sans chien de garde, il serait resté figé jusqu'au soir.
- **Seul le retrait puis le retour de l'alimentation produit ce profil.** Et comme la maison n'a pas
  été coupée, le retrait est **local au Pi** : son bloc d'alimentation, son câble USB-C, son
  connecteur, ou la multiprise sur laquelle il est seul.
- Un disjoncteur qui aurait sauté demanderait un réarmement manuel, et personne n'a touché à rien.

Le coupable le plus probable est donc **le bloc d'alimentation ou le connecteur USB-C du Pi**, par
intermittence — ce qui colle à l'historique de sous-tensions documenté plus haut dans ce README
(20 événements en ~41 h de fonctionnement début octobre, contre 1 sur une semaine entière en
septembre). Un bloc qui se met en sécurité et revient de lui-même après quelques minutes produit
exactement cette signature.

⚠️ **Le compteur de sous-tensions à 0 sur 7 jours ne disculpe pas l'alimentation.** Lors d'une perte
brutale, les dernières secondes ne sont jamais écrites sur le disque — l'arrêt sqlite non propre le
prouve. Le compteur ne peut rien dire de l'instant de la panne. Il dit seulement que le rail ne
s'affaissait pas dans les jours précédents : ce fut une **chute franche**, pas un affaissement
progressif.

**Correctif, déjà prescrit plus haut et maintenant prioritaire :** alimentation officielle
5,1 V / 3 A, câble USB-C court et épais, et si possible un hub alimenté pour sortir le SSD du rail
du Pi.

### ⚠️ Le watchdog du NAS n'a pas alerté — alors que c'est exactement son cas d'usage

`nas/watchdog-ha.sh` interroge `192.168.0.95:8123` toutes les 5 minutes et alerte au 3ᵉ échec
consécutif, soit 15 minutes. La panne a duré de 07:44:24 à 07:59:31 — **15 minutes et 7 secondes**.
Les relèves de 07:45, 07:50 et 07:55 auraient toutes échoué : l'alerte devait partir vers 07:55.

Elle n'est jamais arrivée. Vérifié dans la boîte de Mathias :

| | |
|---|---|
| Courriers du NAS reçus le 22 octobre | **oui** — « Des paquets sur StockageReseau sont obsolètes », 03:31 |
| Courriers auto-envoyés le 23 octobre | **un seul**, sans rapport (« Veille CCAS », 14:11) |
| Alerte du watchdog le 23 octobre | **aucune** |
| Échecs d'envoi de courrier côté DSM | aucun depuis le **23 avril 2026** |

Le canal fonctionne donc, et rien n'est parti. Restent trois explications, à départager dans DSM
— ce journal-ci ne couvre que la catégorie « Système », pas le planificateur de tâches :

1. la tâche planifiée n'est plus activée, ou a été supprimée ;
2. elle tourne mais ne sort pas en code 1 (l'état vit dans `/volume2/docker/ha-watchdog/` :
   `echecs` doit être à `0` en fonctionnement normal) ;
3. la phase de la planification a fait passer les relèves juste à côté du seuil (par exemple
   07:44 / 07:49 / 07:54 / 07:59, la dernière tombant après le retour de HA à 07:59:31 et remettant
   le compteur à zéro). Marge de quelques secondes — auquel cas **`SEUIL=2` serait plus juste**.

À regarder : **Planificateur de tâches → la tâche → « Afficher le résultat »**, et le journal de
DSM, onglet des tâches planifiées.

⚠️ **Second point, indépendant : les notifications auto-envoyées atterrissent à la corbeille.** Le
courrier DSM du 22 octobre et l'alerte « Veille CCAS » du 23 octobre sont tous deux **non lus et
dans la corbeille**. Le NAS s'envoyant les alertes depuis l'adresse de Mathias vers elle-même, un
filtre Gmail les écarte probablement toutes. Même si le watchdog avait alerté, l'alerte aurait fini
au même endroit. À vérifier dans les filtres Gmail.

### Ce que le journal du NAS a montré par ailleurs

- **Le disque 1 est mort en mai 2024.** 693 « I/O error at md2 disk [1], serial [WD-WCC7K0HL89J9] »
  concentrés sur ce seul mois, plus aucun depuis. C'est l'explication du `not_use` et de l'absence
  de redondance signalée plus bas : la grappe tourne sur un seul disque **depuis deux ans et demi**.
- **L'arrêt hebdomadaire programmé ne tourne plus.** Chaque lundi à 04:00 le NAS s'arrêtait et
  redémarrait à 04:15, de janvier au **18 mai 2026**. Puis plus rien. Désactivé, volontairement ou
  non.
- **Espace faible sur le volume 2** : 89 avertissements en septembre, 65 en octobre, contre 4 à 6
  par mois jusqu'en juillet. La situation s'est dégradée d'un ordre de grandeur cet automne.
- Le 21 octobre à 21:50, le NAS a reçu une adresse **`169.254.240.23`** (lien-local) sur LAN 1 :
  il n'a pas obtenu de bail DHCP. Corrobore le problème de DHCP de la box relevé côté Pi.
- Une erreur « System failed to get External IP » le 20 octobre à 14:48.

### Les trois instruments posés

Pour que la prochaine fois soit *connue tout de suite*, pendant que les traces sont encore lisibles.

**1. Deux capteurs `command_line` qui lisent `/proc/uptime`** (`config/commandline.yaml`) :

| Entité | Rôle | Valeur à la pose |
|---|---|---|
| `sensor.pi_temps_de_fonctionnement` | heures depuis le boot de l'hôte | **14,38 h** |
| `sensor.pi_dernier_demarrage` | horodatage du dernier boot | **07:58:00** (± 21 s de la ligne du superviseur) |

Point vérifié et non supposé : **`/proc/uptime` lu depuis le conteneur Core reflète l'HÔTE.** Un
`restart` du seul cœur de Home Assistant ne le remet donc pas à zéro — c'est précisément la
distinction qu'il fallait pouvoir faire.

Le fichier a dû passer de la forme « mapping unique » à la forme « liste » pour accueillir plusieurs
capteurs. **Le bloc historique `CPU Temperature` est laissé tel quel**, sans `unique_id` ni
`state_class` : lui en ajouter créerait une entrée de registre et risquerait de changer son
`entity_id`, référencé en plusieurs endroits du tableau de bord. Coût assumé, déjà documenté plus
haut dans ce README.

**2. Un compteur de démarrages sur 7 jours** (`helpers/modeles_et_historiques.yaml`) :
`binary_sensor.demarrage_recent_du_pi` (modèle, `uptime < 0,17 h`) donne le front, et
`sensor.demarrages_du_pi_7_jours` (history_stats, `type: count`) le compte. ⚠️ Il ne compte **qu'à
partir du 23 octobre au soir** : un history_stats s'appuie sur l'historique du recorder, et le
binary_sensor n'existait pas avant. Le démarrage de 07:58 n'y figure pas.

Détail qui compte : le modèle utilise `float(99)`, pas `float(0)`. Avec un repli à zéro, le capteur
serait passé « on » (0 < 0,17) à chaque indisponibilité de la source — donc à chaque redémarrage de
Core. La valeur de repli d'un `float()` doit tomber **du bon côté** du seuil.

**3. Une notification**, `automation.systeme_alerte_demarrage_non_programme_du_pi` : au démarrage de
HA, elle attend que les capteurs `command_line` se peuplent (`wait_template`, 3 min,
`continue_on_timeout: false`), vérifie que l'uptime est bien inférieur à 10 min — sinon c'est un
simple redémarrage de Core, et on ne notifie pas — puis exclut le créneau du mercredi 3 h et appelle
`script.alerte_famille`.

Les trois tuiles sont dans la vue Technique, section « Redémarrages du Pi ».

### ⚠️ Et une vraie casserole trouvée au passage : la pompe de bouclage ECS

`automation.bouclage_ecs_automatique` enchaînait `pompe ON → delay 4 min → pompe OFF → delay 15 min`
en `mode: single`.

**Un `delay` ne survit pas à un redémarrage : la séquence est abandonnée là où elle en est.** Si le
Pi tombe pendant les 4 minutes — et il est tombé ce matin-là — plus personne n'exécute le
`switch.turn_off`. **La pompe de bouclage reste allumée indéfiniment**, jusqu'à ce qu'un humain s'en
aperçoive.

Second défaut, bruyant : le déclencheur `state` n'avait pas de `to:`, donc il se déclenchait sur
**chaque** changement d'état des cinq entités surveillées, extinctions comprises. En `mode: single`
les tentatives surnuméraires sont rejetées, d'où **1456 « Already running » en 12 h 30** au journal —
un toutes les 31 secondes, qui noyaient tout le reste.

Correctif, exactement le même que celui du sèche-serviettes la veille :

- la durée est portée par **`timer.bouclage_ecs`** (4 min, `restore: true`), qui reprend où il en
  était après un redémarrage, et l'arrêt vient d'un déclencheur `timer.finished` ;
- un **rattrapage** (démarrage de HA + toutes les 15 min) coupe la pompe si elle est allumée sans
  minuteur en cours — le cas d'un minuteur arrivé à échéance pendant que HA était arrêté ;
- **`to: 'on'`** sur le déclencheur ;
- le repos de 15 min entre deux cycles devient une **condition** (`switch` éteint depuis 15 min) au
  lieu d'un `delay` en fin de séquence. Un redémarrage remet ce compteur à zéro, donc le premier
  cycle après un redémarrage peut être retardé de 15 min : l'échec va dans le sens prudent ;
- `mode: queued`, `max: 5`.

### Le reste de ce que le journal a montré

- **DHCP : un bail *neuf* toutes les 5 minutes.** Chaque renouvellement relance `systemd-timesyncd`
  et reconstruit la pile réseau — **288 fois par jour**. Correctif côté box : une **réservation
  d'adresse** pour le Pi et pour la Tydom, avec un bail de 24 h. Non fait, c'est côté box.
- **L'automatisation de la sonnette s'arrête à son étape 2 sur 7** : sa deuxième action appelle un
  service d'une intégration absente. La notification part, les six actions suivantes non. ✅
  **Corrigé le 24 octobre** — voir la section dédiée plus bas. *(J'avais écrit ici « la sonnette n'a
  pas de carillon » et `script.sonnette` : deux erreurs. Il y a un carillon Reolink, et c'est une
  automatisation, pas un script.)*
- 3 délais d'attente RTSP sur `interphone_main` — le flux principal, celui qu'on n'affiche plus.
- 8 télégrammes KNX rejetés sur **`5/3/2`** : un `DPTBinary` écrit dans un objet de luminosité.
- Erreurs `waze_travel_time` récurrentes.
- **CPU 61,8 → 62,3 °C**, contre 52,1 °C quand le ventilateur était branché. Le ventilateur a été
  débranché volontairement ; dossier clos, mais le chiffre est noté.
- Sauvegarde du matin : **05:26:58, 222 Mo, ~93 s**, vers le **NAS uniquement**.
- ⚠️ **Le volume 2 du NAS est à 98,9 %** (3,79 To), état « attention », et le disque 1 est en
  `not_use` — donc **aucune redondance**. C'est la **seule** destination de sauvegarde. Le journal
  DSM a depuis donné la raison du `not_use` : ce disque est tombé en **mai 2024** (voir plus haut).

### 24 octobre 2026 — une plage 6 h – minuit, et le déclencheur de 6 h supprimé

En relisant l'analyse fonctionnelle, Mathias a relevé le point que j'y avais noté comme limite :
**aucune plage horaire**. La pompe pouvait donc partir à 3 h du matin si quelqu'un allumait le
couloir pour aller aux toilettes — 4 minutes de circulation, et un ballon qui recompense les pertes
de la boucle, pour personne.

La condition ajoutée à la **première branche seulement** :

```yaml
- alias: "Entre 6 h et minuit (une borne after seule s'arrête à minuit)"
  condition: time
  after: "06:00:00"
```

Pas de borne `before`. **Une borne `after` seule s'arrête à minuit** — c'est la sémantique
documentée de Home Assistant, et c'est exactement la fenêtre voulue. Un `before: "00:00:00"`
explicite serait ambigu, une fenêtre ne franchissant minuit que si `after` est plus tard que
`before`. Vérifié en direct à **05:01** : la condition rend `false`, et la même avec
`after: "04:00:00"` rend `true` — elle lit bien l'horloge.

⚠️ **La plage ne gate que le LANCEMENT.** L'arrêt en fin de minuteur et le rattrapage restent actifs
24 h/24 : un cycle lancé à 23h58 doit pouvoir se terminer à 00h02, et une pompe trouvée allumée sans
minuteur doit être coupée à n'importe quelle heure. Mettre la condition horaire au niveau des
conditions globales de l'automatisation, ou dans la branche d'arrêt, **laisserait la pompe allumée
toute la nuit** — c'est le piège exact de ce genre de fenêtre.

Le déclencheur « time at 06:00:00 », conservé désactivé depuis l'origine, a été **supprimé** à cette
occasion : il faisait doublon avec la borne de la plage et n'avait jamais servi.

L'analyse fonctionnelle complète (organe commandé et ses adresses KNX, entrées, séquence nominale,
table de vérité, comportement en cas d'incident, limites) vit désormais en tête de
`automations/bouclage-ecs-automatique.yaml`.

## 24 octobre 2026 — la sonnette : une automatisation qui s'arrêtait à l'étape 2 sur 7

`automation.sonette_quand_qqn_sonne` enchaînait sept actions. **La deuxième appelait un service
d'une intégration absente**, et une action inexistante arrête la séquence sans autre trace qu'une
ligne de journal. La notification partait, les six actions suivantes — réglage de volume, deux coups
de carillon sur une enceinte réseau, restauration — n'étaient jamais atteintes. Et rien ne le
signalait.

Les six actions mortes sont supprimées, et l'entrée de configuration de l'enceinte disparue l'a été
aussi, à la demande de Mathias.

### ⚠️ Ce que j'avais conclu à tort

J'ai écrit, le 23 au soir puis le 24 au matin, que **« la sonnette n'a pas de carillon »** et qu'**« il
n'y a plus de haut-parleur dans la maison »**. C'est faux, et Mathias l'a corrigé : **le carillon
d'origine, celui livré avec l'interphone Reolink, est apparié en direct avec lui.** Il sonne par sa
propre liaison, sans passer par Home Assistant — il n'y a rien à y configurer, et rien à y
chercher.

Mon erreur de raisonnement : j'ai inventorié les intégrations de Home Assistant et conclu de
l'absence d'entité à l'absence de matériel. Or le bon carillon de sonnette est justement celui que
Home Assistant ne voit pas — **c'est exactement l'architecture que je recommandais deux paragraphes
plus bas dans la même analyse**, sans voir qu'elle était déjà en place. Le Pi est tombé 14 minutes
la veille ; un carillon qui en dépendrait n'aurait prévenu personne. Celui-là sonne Pi éteint, box
éteinte.

C'est la quatrième fois dans ce projet que je lis une absence de données comme une absence de
phénomène, après le trou du recorder du 7 octobre, les valeurs MQTT retenues, et `UNLOCKED` déclaré
inexistant sur les baies vitrées. **Le symptôme est toujours le même : je consulte l'inventaire
dont je dispose et je conclus sur le monde.**

### Et Home Assistant ne verra pas ce carillon

Le diagnostic de l'intégration `reolink`, relevé le 24 octobre, explique aussi deux entités
indisponibles qui traînaient dans mes relevés depuis des semaines :

```
"model"               : Reolink Video Doorbell PoE
"firmware version"    : v3.0.0.6460_2605211898
"Chimes"              : {}           ← aucun carillon connu de la caméra
"supportDingDongCtrl" : permit 0     ← pas de gestion de carillon du tout
```

*(« DingDong » est le nom interne du carillon chez Reolink.)*

Donc `number.interphone_volume_de_la_sonnette` et `number.interphone_speak_volume` sont
`unavailable` **non pas par panne, mais parce que le micrologiciel de l'interphone ne remonte rien
de son carillon**. Le volume et la sonnerie se règlent sur le carillon ou dans l'application
Reolink. Inutile de recharger l'intégration pour les faire apparaître : elles n'apparaîtront pas.

### Ce qui reste à la charge de Home Assistant : la notification

Le carillon prévient la maison ; la notification prévient ceux qui n'y sont pas, et montre qui
sonne. Elle est devenue un vrai signal :

- **un canal Android dédié** (`channel`), c'est-à-dire l'endroit où le son se règle réellement :
  *Paramètres > Applications > Home Assistant > Notifications > « Sonnette »* ;
- **deux canaux séparés**, « Sonnette » (`importance: high`) et « Sonnette nuit »
  (`importance: default`), pour un signal fort le jour et discret de 21 h à 8 h — l'intention des
  réglages de volume de la version d'origine. ⚠️ L'importance d'un canal Android est **figée à sa
  création** : un canal unique avec deux valeurs d'`importance` ne marcherait pas, d'où les deux ;
- **l'image de l'interphone** (`camera.interphone_sub`, le sous-flux : le flux principal accumule
  les délais d'attente RTSP, et une vignette n'a pas besoin de 2 K) ;
- un appui ouvre la vue Sécurité, icône `mdi:bell-ring` ;
- `mode: queued`, `max: 3`, pour qu'un double appui ne produise pas d'« Already running ».

### ⚠️ Une interaction qu'il fallait ne pas casser

`script.alerte_famille` fusionne le bloc `donnees` **par-dessus** son payload critique — sa propre
description le dit : « Écrase les clés du mode critique en cas de conflit ». Passer `channel` et
`importance` alors que `input_boolean.critique_sonnette` est actif aurait donc **écrasé le canal
`alarm_stream` sur Android et le son critique sur Apple**, c'est-à-dire annulé exactement ce que le
mode critique apporte.

D'où une **première branche à part** quand la criticité est demandée : elle ne passe que les clés
sans conflit (image, icône, `clickAction`). Vérifié par rendu des trois payloads :

```
NON CRITIQUE     → {channel: Sonnette, importance: high, image: …, notification_icon: …, clickAction: …}
CRITIQUE Android → {channel: alarm_stream, ttl: 0, priority: high, importance: high, color: red,
                    sticky: true, + image, notification_icon, clickAction}
CRITIQUE Apple   → {push: {sound: {name: default, critical: 1, volume: 1.0}},
                    + image, notification_icon, clickAction}
```

Les clés critiques sont toutes conservées. Cibles résolues : `notify.iphone_marine` et
`notify.pixel_9a` (`notify.i10_pro` est exclu en dur dans le script, comme prévu).

### Non testé en direct

L'automatisation a été réécrite à 5 h du matin : je n'ai pas déclenché de notification pour ne pas
réveiller la maison. Les payloads sont vérifiés par rendu, les entités existent, l'automatisation
est chargée et `on` — mais le premier vrai coup de sonnette reste à faire.

## 24 octobre 2026 — faire défiler les captures de l'interphone, en deux essais

La tuile « Dernière capture » ne montrait que la dernière. Mathias voulait remonter dans les
précédentes, sur la tuile.

### L'obstacle réel : on ne peut pas lister un répertoire depuis un modèle

L'archive existait déjà — `www/sonette/capture/Archive/`, 45 fichiers horodatés, purgés à 10 jours.
Mais **Home Assistant n'offre aucune fonction de système de fichiers aux modèles Jinja** : les noms
horodatés sont invisibles depuis une tuile. Et le composant `folder`, qui exposerait la liste,
exigerait un bloc `allowlist_external_dirs` dans `configuration.yaml`, donc un **redémarrage**.

### ⚠️ Premier essai, mauvais : un tampon circulaire de 12 fichiers

Noms horodatés inaccessibles → j'ai écrit des noms **fixes** : une troisième copie de chaque capture
dans `defilement/capture_<0..11>.jpg`, l'emplacement donné par un compteur modulo 12, et un curseur
de recul de 0 à 11.

Ça marchait. Mathias a répondu : **« Ça semble figé. Le curseur ne fait rien bouger. »** Il avait
raison, et la plomberie n'était pas en cause — vérifié : l'entité image changeait bien d'état à
chaque mouvement du curseur. Trois défauts de **conception**, tous les miens :

1. **Le tampon partait vide.** Il ne contenait que les 2 captures d'essai que je venais de prendre à
   5 h 40 du matin — deux vues de nuit, identiques à l'œil. Il aurait fallu une semaine de passages
   pour qu'il se remplisse.
2. **Le curseur offrait 11 crans pour 2 images.** L'écrêtage renvoyait les crans 1 à 11 sur le même
   fichier : bouger le curseur de 1 à 4 ne pouvait rien changer. Aucune rétroaction ne le disait.
3. **Les noms fixes perdaient l'horodatage**, donc impossible d'afficher quand la photo avait été
   prise.

Et pendant ce temps, **45 captures horodatées et bien différentes dormaient dans l'archive**, à deux
pas. J'avais construit un magasin vide à côté d'un magasin plein.

### Deuxième essai : une aide `input_select` qui porte les noms de l'archive

Un `input_select` n'a pas de limite de nombre d'options, et son contenu se **remplit par une
action** (`input_select.set_options`). Donc : pas besoin de lister le répertoire — l'automatisation
de capture, qui connaît le nom qu'elle vient d'écrire, l'ajoute elle-même en tête de la liste.

| Pièce | Rôle |
|---|---|
| `input_select.capture_interphone_choisie` | les noms de fichiers de l'archive, la plus récente en tête |
| `image.capture_interphone` | image modèle, URL = `.../Archive/{{ states('input_select...') }}` |

Et comme les 45 fichiers existaient déjà, **la liste a été amorcée avec les 30 plus récents** : la
tuile est utilisable tout de suite, avec 8 jours de vraies captures, au lieu d'attendre une semaine.

L'automatisation ne prend plus que **deux** instantanés au lieu de trois, puis :

```jinja
{% set ns = namespace(l=[]) %}
{% for o in ([fichier] + (state_attr('input_select.capture_interphone_choisie','options') or [])) | unique %}
  {% set d = strptime(o[19:], '%Hh%Mmin%Ssec_%d-%m-%Y.jpg', none) %}
  {% if d is not none and (now().date() - d.date()).days < 10 %}{% set ns.l = ns.l + [o] %}{% endif %}
{% endfor %}
{{ ns.l[:30] }}
```

Trois points qui méritent d'être notés :

- **Le nom du fichier est figé dans une variable** avant la capture, parce qu'il sert deux fois :
  écrire le fichier, puis l'ajouter aux options. Recalculer `now()` une seconde fois donnerait un nom
  décalé d'une seconde, et l'option désignerait un fichier inexistant.
- **`set_options` vient après la capture.** Si `camera.snapshot` échoue, la séquence s'arrête avant,
  et aucune option ne pointe sur un fichier absent.
- **Le filtre des 10 jours relit la date dans le nom du fichier** (`strptime` rend `none` sur un nom
  qui ne correspond pas au format, ce qui sert de garde). C'est lui qui évite qu'une option survive
  au fichier que `delete.files_in_folder` a supprimé — le plafond de 30 ne sert qu'au confort de la
  liste déroulante.

### La tuile

Vue Sécurité, section « Caméras » : l'image, puis deux flèches `shortcut` — **Plus ancienne** et
**Plus récente**, qui appellent `input_select.select_next` / `select_previous` avec `cycle: false`
pour s'arrêter aux extrémités — et une carte `markdown` qui affiche **« Capture 2 sur 30 — 23/10 à
10:14:46 »**. La rétroaction qui manquait au premier essai.

J'avais aussi posé la liste déroulante de l'`input_select`, pour sauter directement à une heure.
Mathias l'a fait retirer : deux flèches et le compteur suffisent, et un nom de fichier brut dans une
liste déroulante n'est pas une interface. **L'aide `input_select` reste** — elle porte les noms et
sert d'URL à l'image ; c'est seulement sa carte qui a disparu du tableau de bord.

L'⚠️ **URL d'une image modèle doit être absolue** : la plate-forme récupère l'image côté serveur et
refuse `/local/...`. D'où `http://127.0.0.1:8123` et `verify_ssl: false` — exactement le motif de la
caméra générique « Dernière capture », dont l'`entity_id` (`camera.127_0_0_1`) vient justement de là.

### ⚠️ La tuile saute toujours sur la nouvelle capture — c'est voulu

Mathias a posé la question : *« quand un screenshot est pris, il vient s'afficher et remplace le
screen regardé même si ce n'est pas le dernier ? »* Vérifié plutôt que supposé — sélection sur la
capture de la veille à 10:13:01, prise de vue déclenchée à 06:12:54, la tuile saute dessus,
position 1 sur 30. C'est `input_select.select_first` en fin de séquence.

Je lui ai proposé la variante « ne suivre que si on était déjà sur la plus récente », avec cet
argument : la notification de sonnette porte déjà l'image en direct, donc faire sauter la tuile
n'apporte rien côté sécurité et ne fait qu'interrompre. **Il l'a écartée : il veut toujours voir la
dernière.** Décision prise, et notée ici comme dans l'en-tête de l'automatisation pour que
`select_first` ne soit pas retiré plus tard en croyant corriger un défaut.

La sélection se fait d'ailleurs **par nom de fichier**, pas par rang : sans `select_first`, une
capture consultée resterait affichée et glisserait simplement d'une position dans la liste.

### Vérifié en direct

Sélection changée à la main → l'état de `image.capture_interphone` change dans la seconde. Flèche
« Plus ancienne » → passage de la capture de 05:56 ce matin à celle de 10:14:46 hier, une image
franchement différente. Automatisation déclenchée → le nouveau nom arrive en tête des options, la
sélection le suit, la liste reste plafonnée à 30.

Le compteur, le curseur de recul et le répertoire `defilement/` du premier essai ont été supprimés.

### Ce qui reste comme avant

L'archive horodatée et sa purge à 10 jours, l'emplacement fixe `capture_interphone.jpg` et la caméra
générique qui le lit. Rien de tout cela n'a été touché.

## Stockage et écritures disque

Le Pi démarre sur un SSD NVMe via un pont Realtek RTL9210, dont le pilote UAS
déclenche des resets sous charge d'écriture soutenue. Correctif définitif :
`usb-storage.quirks=0bda:9210:u` en tête de `cmdline.txt` sur la partition de
démarrage.

✅ **Appliqué le 21 octobre 2026**, le disque ayant enfin été démonté et branché sur
un PC. Procédure complète dans `docs/procedure-quirk-uas.html`. Contenu final du
fichier :

```
usb-storage.quirks=0bda:9210:u dwc_otg.lpm_enable=0 console=tty1
```

L'identifiant `0bda:9210` n'est plus une déduction : il a été relevé sur le matériel
via la propriété **Parent** du disque dans le Gestionnaire de périphériques Windows —
`USB\VID_0BDA&PID_9210\MSFT30012345678904`. Le préfixe `MSFT30` du numéro de série
est la convention par laquelle un périphérique de stockage USB déclare supporter UAS :
il confirme au passage que le boîtier tournait bien en UAS.

⏳ **Vérification en attente.** Le Pi est reparti — donc `cmdline.txt` est valide — mais
la ligne `Quirks match for vid 0bda pid 9210` du journal de l'hôte n'a pas encore été
lue : le connecteur MCP était en échec (502 côté passerelle) au moment du redémarrage.

⚠️ **À revérifier après chaque mise à jour de HAOS.** La documentation officielle
confirme la méthode mais ne garantit nulle part que `cmdline.txt` survive à une montée
de version : les réglages explicitement persistants vivent sur la partition *overlay*,
dont ce fichier ne fait pas partie.

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
seul remède** — appliqué le 21 octobre 2026 (voir « Stockage et écritures disque »). Le
vrai test grandeur nature sera la prochaine mise à jour de Core : si elle passe sans
reset, le correctif est confirmé.

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
| `docs/procedure-quirk-uas.html` | 21 octobre | **Désactiver UAS sur le SSD de démarrage.** Relever le VID:PID par la propriété « Parent », éditer `cmdline.txt`, vérifier la ligne `Quirks match` dans le journal de l'hôte, et le retour arrière |

Les correctifs n'ont **pas** encore été appliqués : ce dépôt reflète l'état du système
*avant* intervention. C'est le point de départ.
