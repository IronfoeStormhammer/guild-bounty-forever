# Guild Bounty Forever 1.2.2 release candidate

Terminal regression checks pass. Complete these live checks before publishing. Record the client build, addon version and results; do not report untested steps as passed.

- First login: the addon opens with demo rows, gold target outlines, arrows and readable coach bubbles. Expected controls advance the guide; Next cannot skip action steps. Check that bubbles never cover their targets or footer tabs. Practise demo acceptance, COD Send/receive, listing confirmation, dropdowns and two applied stats. Back/pause/resume work, and Finish restores real rows and any unsaved draft with no test records or native mail changes.
- /reload after Finish: tutorial stays completed. /gbf help replays from the first interactive step and closing replay preserves completion.
- Listing: save an exact item; create a rule with character-level bounds and multiple applied stat rows; verify confirmation, sound, edit/remove and Details. Test PvP target capture where public APIs permit.
- Real two-character COD, both on 1.2.2 and in the same guild: requester lists, supplier obtains/matches, accepts, agrees quantity/price and queues mail. Mailbox opens without auto-attaching; Prepare delivery fills exact stacks/recipient/COD. Native Send succeeds. Both clients show sent status.
- Requester sees the correlated delivery and manually accepts COD/collects items. No separate addon confirmation is used. Partial attachments stay partial; collecting all completes the claim and reduces the remaining amount once. Supplier sees synchronized receipt/payment status.
- /reload both clients: sent metadata, receipt quantities and payment decision persist. Collect COD proceeds and verify payout tracking only when the server mail format can be correlated.
- Failure checks: wrong/unrelated mail never completes a claim; a full-bag or failed collection remains incomplete; rejected send stays unsent; duplicate mail/bag events do not pay twice. Existing mail drafts are preserved.
- Local real self-mail test is optional and server-dependent. A server rejection must remain unsent and cannot substitute for the two-character test.
- Packaging: ZIP has one top-level GuildBountyForever folder, correct interface/version/TOC files, docs and no temporary files or SavedVariables. Confirm upload-site metadata and supported-client description match the actual Forever build.

Ready to upload after live checks pass; tutorial testing alone is insufficient.
