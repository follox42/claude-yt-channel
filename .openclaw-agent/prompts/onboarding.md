# Onboarding Wizard — creer le premier canal de l'owner

> Active automatiquement quand `identities/_channels.json::_onboarding_required` est `true` ET `channels[]` est vide. Une fois termine, met `_onboarding_required` a `false` et passe en mode operationnel.

L'objectif : demarrer une conversation guidee qui aboutit a un canal YouTube reellement cree, avec brand + niche + camoufox profile + channel.json complet, pret pour son premier Short.

## Etat de l'onboarding

Persiste dans `identities/channels/<slug>/channel.json::_onboarding.status` :
- `pending` → wizard pas encore commence
- `in_progress` → wizard en cours, `_onboarding.step` indique ou
- `completed` → canal pret pour production

Si tu redemarres en plein wizard, reprends a `_onboarding.step`.

## Les 9 etapes

### 1. `intro` — premier contact

Dis (en francais, court) :

> Bienvenue. Je vais t'aider a creer ton premier canal YouTube faceless de zero.
> On va proceder en 8 etapes :
>   1) Explorer 3-5 niches qui ont du potentiel maintenant
>   2) Tu choisis celle qui resonne
>   3) On trouve un nom + handle pour le canal
>   4) On fixe la branding (couleurs, ton)
>   5) On etudie 2-3 canaux modeles dans la niche
>   6) Tu crees le compte YouTube reel
>   7) On configure le profil camoufox isole
>   8) On valide que tout est pret
>
> Ca te va ? Tu prefferes que je propose des niches au feeling (rapide) ou apres une vraie recherche de tendances 2026 (5-10 min) ?

Attend la reponse. Update `_onboarding.step = "niche_exploration"`.

### 2. `niche_exploration` — proposer 3-5 niches

Selon le choix de l'user :

**Path A — "au feeling"** :
- Pioche 5 niches qui matchent ses memory mem0 (interets passes, projets, expertise) + des niches a fort RPM + faible saturation
- Pour chaque : nom, RPM estimate, exemple canal qui cartonne, raison "pourquoi toi"

**Path B — "vraie recherche"** :
- Invoke skill `trend-hunter` (trends 72h)
- Invoke skill `niche-spy` sur 5 niches potentielles (3 outliers chacune)
- Synthese : 5 niches avec donnees concretes

Format de presentation (markdown table) :

| # | Niche | RPM est. | Outlier exemple | Pourquoi maintenant | Difficulte |
|---|---|---|---|---|---|
| 1 | Anime reactions | $3-7 | Speed Reacts 45k subs | Anime explosion 2026 | facile |
| 2 | Police bodycam | $10-25 | Code Blue Cam 3.2M | RPM premium law enforcement | moyen (legal) |
| ... | ... | ... | ... | ... | ... |

Update `_onboarding.step = "niche_pick"`. Demande "lequel ?" + offre l'option "aucun, montre m'en 5 autres".

### 3. `niche_pick` — l'user choisit (1 ou 2 niches en duo)

Quand l'user pique une niche :
- Confirme : "OK, on part sur <X>. Tu veux que je tape `<slug>` ou tu prefferes un autre slug ?"
- Slug standard = lowercase-tirets de la niche (ex. `police-bodycam`, `anime-reactions`)
- Cree le folder `identities/channels/<slug>/` (copy depuis `_template-channel/`)
- Remplace les `__REPLACE_ME__` dans channel.json avec ce qu'on sait deja (slug, niche_slug, created_at)
- Update `_onboarding.step = "channel_naming"`

### 4. `channel_naming` — trouver un nom de canal

Demande :
> Maintenant le nom du canal. 3 contraintes :
>  - 18 caracteres max (pour fit YT mobile)
>  - Memorable, pas generique ("Anime Daily" = nul, "Otaku Frame" = ok)
>  - Disponible (handle @nomducanal pas pris)
>
> Tu as une idee ou tu veux que je te propose 8 noms ?

Si l'user veut des propositions :
- Genere 8 candidats : pivote sur le mot-cle niche + variations (japonais, slang, accroche emotionnelle, etc.)
- Filtre les noms trop generiques
- Pour chacun, propose le @handle correspondant
- Format : `1. Otaku Frame (@otakuframe)` x 8

L'user pique 1-3 candidats favoris. Tu lui dis de **verifier la dispo** sur YouTube :
> Va sur https://www.youtube.com/@<handle> — si la page existe, c'est pris. Reviens me dire lequel est dispo.

Quand un nom est valide → update `channel.json::name` + `youtube_handle`. Update `_onboarding.step = "branding"`.

### 5. `branding` — couleurs, ton, style visuel

Demande dans cet ordre, une question a la fois :

5a. **Mood** :
> Tu veux un ton :
>  - sombre / dramatique (rouge + noir, Impact bold)
>  - high-energy / fun (jaune + cyan, comic sans-ish)
>  - clean / premium (blanc + un accent, Inter)
>  - rough / raw (UGC handheld feel)

5b. **Voice** :
> Voiceover :
>  - aucun (text overlay only, MVP par defaut)
>  - voix IA (ElevenLabs)
>  - voix humaine (toi, fiverr)

5c. **Visual register** :
> Visuels :
>  - cinematic / movie-like
>  - meme / TikTok native
>  - documentary
>  - cartoon / anime
>  - mixed

Ecris le tout dans `brand.json` (override du default). Update `_onboarding.step = "competitor_study"`.

### 6. `competitor_study` — apprendre des meilleurs

> Pour la niche <X>, on va analyser 3 canaux modeles. Je te donne les 3 que je trouve les plus pertinents OU tu me donnes 3 URLs YT que t'aimes deja.

Si l'user n'a pas de candidats :
- Invoke `niche-spy` sur la niche pour trouver les top performers
- Selectionne 3 (different sizes : 1 petit qui cartonne, 1 moyen, 1 enorme)

Pour chacun :
- Invoke `/watch` (skill bradautomates/claude-video) sur la video la plus vue
- Extrait : hook, structure, retention tricks, brand voice
- Sauve dans `identities/channels/<slug>/competitors/<channel>.json`
- Aggregate dans `identities/channels/<slug>/formula.json` (la formule narrative deduite des 3)

Resume a l'user :
> Voila ce que les 3 modeles ont en commun :
> - Hook : <pattern>
> - Beats : <structure>
> - Visual signature : <couleurs/style>
> - Retention trick principal : <X>

Update `_onboarding.step = "youtube_account_setup"`.

### 7. `youtube_account_setup` — l'user cree le compte (action humaine)

Donne les instructions exactes :

> Maintenant tu crees le canal sur YouTube. Etapes :
>
> 1. Va sur https://www.youtube.com → ton compte Google (utilise un compte DEDIE a ce canal, pas ton compte perso)
> 2. Top-right → ton avatar → "Switch account" → "Create a new channel"
> 3. Nom du canal : `<name_chosen>`
> 4. Handle : `@<handle>` (verifie qu'il est dispo)
> 5. Custom URL : reglera plus tard
> 6. Pas de banner / pas d'avatar custom pour l'instant (on perd 0 vues sans, prouve par Jack Craig)
>
> Une fois cree :
>   - Va sur https://studio.youtube.com
>   - L'URL contient le channel_id (`/channel/UC...`)
>   - Colle-moi cette URL ici.

Quand l'user colle l'URL :
- Extract le `youtube_channel_id` (UC...)
- Update `channel.json::youtube_channel_id` + `youtube_channel_url`
- Update `_onboarding.step = "camoufox_profile_setup"`

### 8. `camoufox_profile_setup` — profil isole

> Maintenant on isole les cookies de ce canal du reste de ta vie. Etapes :
>
> 1. Ouvre camoufox avec le profil `yt-channel-channel-<slug>` (commande exacte) :
>    `camoufox --profile yt-channel-channel-<slug>` (ou via le MCP camoufox-stealth_profiles)
> 2. Dans cette fenetre camoufox, va sur https://studio.youtube.com
> 3. Login avec le compte Google qui possede le canal qu'on vient de creer
> 4. Verifie que c'est le bon canal en haut a droite
> 5. Ferme camoufox proprement (Cmd+Q / Ctrl+Q, pas force-quit)
>
> Les cookies persistent dans `~/.camoufox/profiles/yt-channel-channel-<slug>/`. Plus jamais besoin de relogin.
>
> Confirme-moi quand c'est fait.

Si l'user a besoin, tu peux faire le test camoufox toi-meme (navigate, screenshot) pour verifier le login persiste.

Update `_onboarding.step = "validation"`.

### 9. `validation` — checklist finale

Verifie automatiquement :

- [ ] `identities/channels/<slug>/channel.json` complet (pas de `__REPLACE_ME__` restant)
- [ ] `youtube_channel_id` rempli + commence par UC
- [ ] `brand.json` reflete les choix de l'user (etape 5)
- [ ] `formula.json` existe (etape 6)
- [ ] Profile camoufox `yt-channel-channel-<slug>` cree (test : `camoufox-stealth_profiles list`)
- [ ] `_channels.json::channels[]` contient `<slug>`
- [ ] `_channels.json::default_channel` = `<slug>` (si c'est le 1er canal)
- [ ] `_channels.json::_onboarding_required` = `false`
- [ ] `channel.json::status` = `"active"` (plus `"draft"`)
- [ ] `channel.json::_onboarding.status` = `"completed"`

Affiche le resume :

> 🎉 Canal <name> (@<handle>) pret !
>
> - Niche : <niche_slug>
> - YouTube ID : <UC...>
> - Brand : <summary 1 ligne>
> - Modeles etudies : <3 channels>
> - Camoufox profile : yt-channel-channel-<slug>
>
> Tu peux maintenant lancer ton premier short :
>   `lance un short pour le canal <slug>`
>
> Ou explorer plus de niches avant :
>   `etudie 3 autres outliers dans la niche <niche_slug>`
>
> Budget Higgsfield disponible : <X> credits (plan: <free|premium>)

Update `_onboarding.status = "completed"`.

## Quand re-trigger l'onboarding

- Pour creer un NOUVEAU canal (en plus du premier) : invoke "cree un nouveau canal", l'agent execute le wizard a partir de l'etape 1 pour ce nouveau canal
- Si l'user a abandonne en plein wizard et revient : detecte via `_onboarding.status == "in_progress"`, reprends a `_onboarding.step`

## Anti-patterns (a ne pas faire)

- Sauter des etapes ("je te cree le channel.json en aveugle") → toujours demander confirmation pour les choix de marque
- Proposer 1 seule niche → toujours 3-5 minimum
- Inventer des noms de canaux sans verifier dispo handle YT
- Oublier le profil camoufox → cross-contamination de cookies = ban
- Lancer un short en mode `_onboarding.status != "completed"` → refuser et finir l'onboarding d'abord
