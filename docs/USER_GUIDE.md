# Guild Bounty Forever 1.0.0

**Implemented, with terminal regression checks passing; live input and multiplayer verification still required.** This update preserves the existing Forever/Camelot visual design and repairs the creation workflows. Target: Forever 1.60.1 build 70707, interface 16001.

## Install and open

Copy `GuildBountyForever/` into `_forever_/Interface/AddOns/`, enable the addon, then `/reload` (restart if installing for the first time). The deployment tool `python tools/install.py --addons-dir /path/to/_forever_/Interface/AddOns` stages and verifies this folder, backs up an existing installation outside AddOns, and replaces the whole folder so stale runtime files cannot remain.

Use `/gbf` to open the board. Drag its title bar to move it. Position and the active tab persist. The native portrait frame, rock background, inset borders, gold fonts, red buttons, tabs, item widgets, money display and tooltips are retained. The heart icon is original bundled artwork; the main UI uses native game artwork. No external libraries are bundled.

## Interactive first-launch tour and help

The required tour opens Guild Bounty itself with clearly labelled example listings, claims and history. A compact coach bubble explains the highlighted control; a gold outline and downward arrow identify it. Action steps advance by clicking that control, with Next disabled until the interaction is done. Observational steps use Next, and Back lets you revisit a lesson. Closing pauses; `/gbf` resumes the saved step. `/gbf help` restarts the practice tour.

The tour uses the real board tabs and controls, plus a separate practice form. You inspect a demo request, accept it, choose quantity, practise COD preparation/Send and collect a simulated delivery. Then you practise exact-item listing and confirmation, rule dropdowns, two applied stat rows, a PvP target, Mine filters and History. The demo mailbox never touches native mail. No example is saved or synchronized, no items move and no gold is transferred. Original drafts, listings and navigation are restored on exit. Background real mail recording and synchronization continue.

First launch requires reaching Finish. Completed users can replay and pause without revoking completion. The redesigned tour uses a new progress version, so the previous text-page completion does not skip it. Confirmed real COD collection continues to record receipt/payment automatically; Manual review remains an exceptional override.

## Dropdowns and bottom navigation (1.1.4)

Rule creation now uses native dropdown menus populated with localized item type/subtype names and readable equipment slots. The board also names these criteria. The four bottom navigation controls use native buttons fully inside the footer, with one highlighted selection; this removes the misaligned selected-tab artwork shown in the live screenshots. Terminal checks exercise menu callbacks, dependent subtype reset, save/edit restoration and footer selection/placement. Live appearance still needs verification.

## Live error repair (1.1.3)

The latest live chat errors exposed a shared construction failure: missing actions/error-label fields indicated that the main window stopped building partway through. Essential controls now finish before optional scrollbar setup, and incomplete windows remain hidden with a visible construction error. The scrollbar is created using the EventFrame type declared by its native template; optional setup exceptions are isolated, with mouse-wheel scrolling retained. The status command reports the captured scrollbar setup failure if one occurs.

The live Save error also confirmed that the legacy global money formatter is unavailable. All addon-owned money strings now use the source-confirmed `C_CurrencyInfo.GetCoinTextureString` API, with safe compatibility/native-icon fallbacks. This fixes formatting in the save confirmation and Details. Regression tests run with the legacy global absent, and repeat the full UI workflow with failing scrollbar initialization, an unsupported scrollbar script hook, and healthy setup. Live retesting remains necessary; the exact earlier native construction exception was not included in the screenshot.

## Save, Details and selector repair (1.1.2)

Save now opens a native confirmation showing the request, quantity and promised reward. Cancel keeps the draft without writing; confirm commits once, plays the native quest-log sound, returns to the appropriate board and selects the exact created request (including when several records share a timestamp). A visible saved message confirms completion. Existing requests are preserved.

Type selectors explicitly register native left-click handling, use native Enable/Disable selection controls and report handler errors visibly. Details has an explicitly anchored scroll child and bounded text height. Navigation initialization tolerates native template differences instead of leaving a partially initialized window; tabs sit at the lower edge within the window. A UI rendering failure cannot make a successful database write fail, reducing the risk of repeated saves. Any remaining runtime action failure is shown in chat and `/gbf status` as “Last UI error.” Live retesting is still required.

## Create a request

The form has three directly selectable buttons: **Exact Item**, **Rule Request**, **PvP Target**. Common reward and note fields remain when switching. Mode-specific data is isolated; a captured target GUID is cleared when leaving PvP mode. Cancel writes no records, history or network updates, and opening a new form clears its draft.

**Exact Item:** type a numeric ID such as `19019`, paste an item hyperlink, focus the field and shift-click an item, or drop a bag item onto the field or preview slot. A held cursor item can also be placed by clicking that slot. Only a recognized item cursor is cleared, after its ID has been accepted. No inventory item is moved or transferred. A resolved item shows the game's icon, quality-coloured link, item level, required level and inventory slot; hover the icon for GameTooltip. Uncached data is requested, and Save refuses to create an unresolved or invalid item request. If a supplied ID never resolves, check it rather than saving a broken item.

**Rule Request:** choose named item type, subtype and equipment-slot dropdowns; no sample item or ID is required. Level limits refer only to the character level required to use the item. Item-level controls have been removed. Choose a stat, enter minimum and/or maximum, then press **Apply stat**. A confirmation sound plays and the applied criterion becomes its own locked row. The picker clears for another stat; applied stats stay visible independently. Use a row's **Edit** to unlock its limits and apply again, or **Remove** to delete only that criterion. Three rows are visible at once; scroll or use Previous/Next to reach additional stats. Save requires every unfinished stat entry to be applied. All locked criteria must match. Invalid/reversed ranges do not apply or play success audio. Existing contracts retain their stored criteria, including any legacy item-level bounds. Matching uses native item data; tooltip-only procs and effects are not inferred.

**PvP Target:** enter the full two-part character name, such as `Ironfoe Stormhammer`, or target an opposing player and press **Use target**. NPCs and friendly targets are rejected. The target button captures only publicly available GUID, faction, class, level and name data. PvP quantity is fixed at one. Save immediately selects the corresponding Requests or PvP board.

Quantity must be a positive integer (maximum 100000 for item requests). Gold is a nonnegative whole number; silver and copper must be 0–99. Notes allow 500 characters and remain within a single native scrolling edit box. Ordinary editing keys, selection and paste are handled by the native EditBox; Enter/Escape release focus. Click another input to move focus, or the form background to release it.

## Forever identity and rulesets

Forever uses a two-part player name. Camelot's native `NameUtil` combines `UnitNameUnmodified`'s first name and surname using `Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR`. The addon uses that native separator, accepts a typed space, preserves the two components and display name, and never strips the separating space. A hyphen is not imposed as a naming convention.

Ownership prefers the observed player GUID. Where no GUID is available, a normalized full name plus ruleset is used. The current ruleset is detected using `C_GameRules.IsGameRuleActive` with `Enum.GameRule.PvPRuleset` and `RPRuleset`, producing PvE, PvP, RP-PvE or RP-PvP. Region is recorded when `GetCurrentRegion` exposes it. Unavailable context remains unavailable; the addon does not ask users to invent it. `/gbf debug identity` reports exactly what the running client supplies.

Manual PvP names remain explicitly unresolved. Targeting and readable combat events populate a separate local observation index, including source, observer and time. Matching and the details view enrich an unresolved identity from an unambiguous observation without rewriting the creator's entered contract. An exact GUID takes priority. Name-only matching requires a full normalized two-part name and matching known ruleset context. Conflicting observed GUIDs for the same name/context prevent name-only matching. Captured ruleset describes the observation's context, rather than claiming to know a remote character's unexposed home context.

## Solo real-mail test

Run `/gbf testcod`, select your own open item bounty, enter quantity and COD price, then click **Start real mail test**. This creates a labelled real local claim using your actual items and bounty progress; it is available only while unguilded. Go to a mailbox and open mail. The addon shows **Prepare delivery**; click it to attach the exact matching items, split stacks and fill your name and COD amount. Review the native draft and manually press **Send**. A successful server send publishes sent status. If your server permits self-mail, receive the matching delivery normally to exercise recipient tracking too. A server rejection leaves it unsent; the addon cannot bypass mail restrictions or invent receipt. A separate requester is necessary if the server rejects self-mail.

**Preview only** remains read-only and exercises selection/split planning without touching mail or records. It does not test native delivery.

## Claims, loot, payment and history

Requests show real item metadata, remaining/total quantity, requester, reward and status. Mine filters creations, submitted/accepted claims, reviews and completed activity. Row tooltips preserve full names even if a long row label is visually shortened.

Self-loot chat formats and inventory increases from `BAG_UPDATE_DELAYED` feed the same matcher. Bag totals are seeded at login/context changes, so opening bags or moving/splitting an existing stack does not create acquisition evidence. Active prompts coalesce the same item/request across both event sources, and a short cooldown prevents immediate repeats after dismissal. Later acquisitions can prompt again; old saved item dismissals no longer silence them permanently. Your own bounties also prompt, opening their details without creating a self-payment claim. Run `/gbf matches` to inspect items already held in your bags; this is labelled as an inventory check rather than new loot. Native localized stack formats, including positional placeholders, determine quantity. Uncached rule matches retry for up to 30 seconds. Inventory increases can also reflect trades/mail rather than loot; their evidence is labelled accordingly.

The compact match prompt shows the item portrait (or PvP class/faction artwork), requester, found/remaining quantity, reward and a shortened note. PvP rank/title/badge are shown only if a public getter or saved observation provides them; unavailable ranks are labelled explicitly. Your own bounty has two buttons instead of a duplicate View action.

**Arrange delivery** selects quantity and opens an editable COD amount, suggested in proportion to the full request. **Use COD mail** accepts the delivery plan and tells you to visit a mailbox. Opening mail shows **Prepare delivery**; no attachments move until you press it. The addon fills matching item stacks, exact quantity, requester, subject/body and COD amount. You review and manually click the game's **Send** button. Existing drafts and occupied cursors are preserved. Failed preparation may leave a partial draft to inspect; no mail is sent automatically. The pending mailbox task survives reload. **Mail COD** on the claim resumes this workflow.

A verified send plus MAIL_SEND_SUCCESS stores supplier-authored sent time, unique subject, COD amount and exact attachment totals on the claim, then submits it. This synchronizes to the requester. The requester is notified when a matching delivery is visible in their inbox. They inspect the native mail and manually accept COD/collect items. Tracking requires the matching sender/subject, native collection activity, success, attachment removal and corresponding bag increase. Confirmed partial receipts are retained; the bounty completes only after every claimed item is received and COD is accepted (or the agreed amount is zero). Requester-authored receipts and payment decisions synchronize back to the supplier.

Supplier collection of COD proceeds is recorded only when a native money collection can be correlated by sender, unique subject and amount, plus a confirmed wallet increase. If server payment-mail formatting does not retain those details, proceeds remain unconfirmed rather than guessed. Opening mail alone, unrelated events, failed sends, returned/deleted items and mere bag gains do not count as completion. Collection while the addon is disabled cannot be reconstructed automatically; manual review remains available. Guild peers should use **1.0.0** to understand the new delivery/receipt fields. Native API/event behavior and server-specific self-mail/payment-mail rules still require live verification.


## Synchronization and SavedVariables

A guild is required for communication. Unguilded local creation works in an isolated local partition and the UI says so. On guild availability, the addon refreshes context/roster and schedules synchronization without a restart. Local drafts remain separate from published guild data.

SavedVariables: `GuildBountyForeverDB`, written by WoW on logout/reload to `_forever_/WTF/Account/<account>/SavedVariables/GuildBountyForever.lua`. Schema 2 stores partitions by region/ruleset/guild, objects, replicated history, claims, observations, ignored matches, sync metadata and shared UI preferences.

Schema-1 migration remaps object IDs, parent/decision references, ownership, history and ignored matches while preserving UI state. It removes the obsolete location-based naming model. Names irreversibly compressed by the previous build are not guessed: records remain labelled unresolved, with GUIDs retained where available. Previously stored current-character names are recovered against the native identity. Other old guild partitions remain retained; matching guild data attaches when that guild becomes known, including delayed login availability. Migration is version-gated and idempotent. A newer unsupported schema disables initialization instead of overwriting data. The installation backup preserves the old addon; normal file backups of SavedVariables should be taken with WoW closed.

Protocol **GBF2** separates this identity model from obsolete development clients. All members should update. HELLO/VERSION compare inventory digests; paged SUMMARY requests missing/newer records using correlated GET/OBJECT. UPDATE author identity is checked against the sender's guild roster name/GUID. Duplicate and reordered packets do not create new logical objects. Higher revisions win; canonical encoding breaks equal-revision ties. Immutable history envelopes retain earlier activity for offline peers. Closed objects act as retained tombstones.

Initial presence is delayed seven seconds; changed inventories are reconciled periodically. Packets use 180-byte chunks, bounded assembly lifetimes/concurrency, sender rate limits, and one outgoing packet per 0.3 seconds. Payloads carry ruleset/region context and mismatches are rejected. Guild-channel recipient scope is supplied by the game; source inspection does not prove whether guilds can span different rulesets. Explicit context checks avoid assuming that they cannot. Actual delivery, permissions and cross-context behavior require two live clients. Peer snapshots rely on guild trust and cannot authenticate an offline author's original message. The defensive archive ceiling is 10000 records including history; a request supports at most 40 decisions. No backend is used.

## Blizzard blocked-action hotfix (1.1.2)

Item-link capture now uses `hooksecurefunc` post-hooks. It does not replace Blizzard's dispatcher or change its return values; other native shift-click behavior remains controlled by the game. Internal combat event registration was removed. Standard combat registration occurs only if an accessible public getter exists and the client reports unrestricted access. A blocked action is recorded by its exact function name and shown by `/gbf status` for diagnosis. No security warning is hidden or bypassed. Reload is required after installing to discard any dispatcher replacement left in memory by 1.1.0. The screenshot alone does not identify which protected action triggered the warning, so these changes remain a conservative hotfix pending live retest.

## Diagnostics

Normal mode is quiet. `/gbf debug` toggles diagnostics, with a bounded in-memory log and native chat output. Subcommands below require it and create no test production records/history:

| Command | Result |
| --- | --- |
| `/gbf help` | Replay the complete guided tutorial |
| `/gbf status` | Version, build/interface, schema, ruleset, guild/sync counts, combat getter availability |
| `/gbf testcod` | Own-bounty preview or real local mail test; real test requires unguilded mode |
| `/gbf matches` | Check current bags for matching open bounties and open match prompts |
| `/gbf sync` | Announce presence using normal synchronization |
| `/gbf debug identity` | Full native identity, components, GUID, ruleset, separator |
| `/gbf debug target` | Validate/capture the current opposing player and print available fields |
| `/gbf debug item 19019` | Request/inspect item metadata without creating a request |
| `/gbf debug sync` | Sync diagnostics and active context |
| `/gbf debug records` | Counts by record kind and migration report |
| `/gbf resetposition` | Center the window |

Debug logs include focus acquisition, captured item IDs, API failures and rejected updates. Important runtime exceptions are reported while debug is enabled. The old simulated `testmatch` creation command is removed.

## Validation and live checklist

This package is a release candidate until the live checks in `docs/RELEASE_CHECKLIST.md` pass, including a complete two-character COD transaction and reload on both clients. Tutorial testing alone does not verify delivery/payment.

`python tools/validate.py` checks the TOC/load order, runtime file inventory, syntax with LuaJIT/Lua 5.4, and deterministic tests. Tests cover names/separators, all four rulesets, observation enrichment, GUID matching, strict item/form validation, mode isolation, populated migrations, late guild availability, sync duplicates/conflicts/recovery, loot quantities/dedup, native handler wiring and bootstrap. They **cannot prove keyboard, mouse, pixel layout, live API values, delivery, or gameplay inside WoW**.

1. `/reload`; `/gbf status`; enable debug and inspect identity. Verify both name parts and automatic ruleset. Open/move the window and confirm position survives reload.
2. Create Exact Item requests by ID, focused-field shift-click, and drag onto the slot. Check icon/name/tooltip/preview and Save. Confirm an invalid/unresolved ID cannot save.
3. Switch directly through all three modes. Type a full PvP name, edit reward/quantity/note, and save. Use target on an opposing player; check captured fields. Cancel another draft and verify no activity is added.
4. Create a rule request, reload, and inspect its criteria and records. Verify Backspace/Delete/arrows/Home/End/Ctrl+A/paste, Enter/Escape and clicking between fields in the live client.
5. With another updated guild member, create/edit/close/claim and reload on both sides; check convergence and no duplicates. Obtain a matching item on the second player, Accept, submit and review/payment/rejection.
6. Kill the captured PvP target with personal participation. Inspect actual evidence, submit, and review manually. If detection is unavailable, use status/debug output to identify the exposed API boundary.

Runtime modules: `Identity` native names/context/observations; `Migration` schema conversion; `Form` pure validation; `UI`/`Native` native board/input; `Items` metadata/rules; `Loot` acquisitions; `PvP` detection; `Claims` workflow; `Models`/`Database` validation/state; `Sync` network; `History` replicated events; `Notifications`; `Debug`; `Bootstrap`; `Util`; `Codec`. Source discoveries and remaining uncertainties are in `docs/CLIENT.md`.
