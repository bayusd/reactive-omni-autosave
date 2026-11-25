# Submission checklist — Reactive Omni Buildathon (DoraHacks)

Event: Reactive Omni Buildathon — track **"Set It and Forget It"**
Submission closes: **5 Dec 2026, 20:00 UTC**
Submit at: https://dorahacks.io/hackathon/reactive-omni-buildathon/detail
(Boss registered as **Jabrik78** via GitHub on 25 Nov 2026.)

## Deliverables required by the event

- [x] Public code (this repo, MIT license) — **PUSHED 25 Nov 2026** (Boss's
      word given in chat): https://github.com/bayusd/reactive-omni-autosave
      (public, main @ 8923c2b, verified reachable read-only)
- [x] Contracts deployed on testnets (see below)
- [x] Transaction hashes proving the full loop: origin event tx →
      reactive tx → destination callback tx  ← **DONE 25 Nov ~14:51 WIB
      (see "Stage 2 — loop fired" below)**
- [ ] Demo video < 3 min (plan below)
- [ ] BUIDL submission on DoraHacks before the deadline

## Stage 2 — FIXED + LOOP FIRED (25 Nov ~14:32–14:51 WIB, Boss: "Gas, perbaiki + redeploy sekarang")

**The loop works.** One trigger deposit ran the full automation end to end
in ~14 seconds (origin block → callback block):

| Step | Chain | Tx |
| --- | --- | --- |
| 1. Pot deposit 0.00002 ETH (`DepositMade`) | Base Sepolia, block 63355198, 07:48:28 UTC | `0xc33c5d7e5f1f02493c63dfacf025c9e7858e979674dc3dca317c8db7e4d920c9` |
| 2. Reactive `react()` → `CallbackSent` | Lasna, block 9201585 | `0x34f18a01bf757965da6044759e615376eb0ed14b384c062251331d44130ebc31` |
| 3. Callback `executeSweep` → `SweepExecuted` | Base Sepolia, block 63355205 | `0x1dcc5461a5d920cba8a65c3b172c0faf7d11d0094ba29ae1d4844934b718749a` |

Proof on-chain: reactive `callbacksSent` = 1, `lastDepositAmount` =
0.00002 ETH; executor `sweepsExecuted` = 1, `totalSwept` = 0.000002 ETH
(exactly 10% of the deposit); pot balance 0.00282 → **0.002822 ETH**;
reactive debt 0, reserves 0.02 → 0.0025313 lREACT after the reaction
(one reaction costs ~0.0175 lREACT).

### What changed in stage 2 (v1.1)

- **Filter fix:** `AutoSaveReactive` constructor now subscribes with
  topic2/topic3 = `REACTIVE_IGNORE`
  (`0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad`,
  official docs value) instead of literal `0`. The deploy receipt's
  subscription log shows REACTIVE_IGNORE in both positions.
- **Constructor recipient:** the executor address is wired in the
  constructor (no separate `setRecipient` tx needed — saved ~0.005 lREACT).
  The executor was deployed FIRST with the reactive address predicted via
  CREATE nonce (Lasna nonce 5 → `0x704F…8d30C`); the prediction hit exactly.
- **Classic v2 + CronSweep RETIRED** — not redeployed (retired
  architecture, both blacklisted with ~0.0247 REACT debt left abandoned).
  Only the new-docs Omni v1.1 pair is live now.

### New v1.1 deployments

| Contract | Chain | Address | Deploy tx |
| --- | --- | --- | --- |
| AutoSaveReactive v1.1 | Lasna 5318007 | `0x704F877130F504A45881cE494777356fEb78d30C` | `0x8e90d9981df51f1ffd838090965aec519fb50cada9e82c77bb11f329632d50ee` |
| AutoSaveExecutor v1.1 | Base Sepolia 84532 | `0xd06fBEa650d47c7339728a701C5b4fF4E4Cc4Dbf` | `0xa5a8e1d5faff02f6fe1034642949ef80617df20961ff9df87665fa1db3e4fa5c` |

Reserves: reactive 0.02 lREACT (`depositTo` tx
`0xf114741cfb21489444e03a00347ea4fc51c941f07348a3447b3ba2a0559c9469`);
executor float 0.000005 ETH + proxy reserves 0.00001 ETH
(`depositTo` tx `0x53fa28980031711ac88596e77f2087acae549b8c041af0b753ce25b52d9319e1`).
Pot reused (same `0x5e50…87b`).

### Funding notes (stage 2)

Testnet funds were nearly dry, topped up only via the official Reactive
faucet (1 Base Sepolia ETH → 100 lREACT): 0.0002 ETH → 0.02 lREACT
(tx `0x2afaFD…` call, see logs), 0.00005 ETH → 0.005 lREACT
(tx `0xddaab035165106c3c5e92a8848253dc048c021cb724af9bda123898202640a12`),
0.00005 ETH → 0.005 lREACT
(tx `0x43634bab68ec0f510a03b90c99c33b776e53348d3be1490e29011366c0d78620`).
Ethereum Sepolia RPCs were all unreachable from this VM (Cloudflare/plan
blocks) so the 0.0005 Sepolia ETH there could not be used. Lasna gas price
spiked to ~175 gwei once mid-deploy (settled back to 100 gwei); deploy gas
~1,008,160. Remaining funds after stage 2: Lasna ~0.0032 lREACT,
Base Sepolia ~0.000049 ETH — reserves (0.0025 lREACT) cover at most one
more reaction; any further test needs a fresh faucet round (Boss's call if
more Base Sepolia ETH is needed — public Base Sepolia faucets need a
browser/account step).

### Remaining before submit

1. Demo video < 3 min (plan below) — needs the loop evidence above.
2. BUIDL submission on DoraHacks before **5 Dec 2026 20:00 UTC**.
3. Repo re-push with v1.1 (this file + README updated) — done below.

## Deployed contracts — LIVE (v1.1, stage 2)

| Contract | Chain | Address | Deploy tx |
| --- | --- | --- | --- |
| AutoSavePot (origin, reused) | Base Sepolia 84532 | `0x5e50bd3892Dd44e38D98e272ceE8604331bda87b` | `0xb98845a81bcb2c6375f6724451b1ab695f8f7f5c1b7c8af544bc8db132a2c885` |
| AutoSaveReactive v1.1 | Lasna 5318007 | `0x704F877130F504A45881cE494777356fEb78d30C` | `0x8e90d9981df51f1ffd838090965aec519fb50cada9e82c77bb11f329632d50ee` |
| AutoSaveExecutor v1.1 | Base Sepolia 84532 | `0xd06fBEa650d47c7339728a701C5b4fF4E4Cc4Dbf` | `0xa5a8e1d5faff02f6fe1034642949ef80617df20961ff9df87665fa1db3e4fa5c` |

Retired (stage 1, classic architecture — blacklisted, debts abandoned):
v1 `0x23c42C…799D`, Executor v1 `0x59bA7D…8583`, ReactiveV2
`0x9B181d…6dC`, ExecutorV2 `0x136fe2…2Fec`, CronSweep `0xa67B84…45BB`
(full stage-1 table + txs preserved in the "Open issue" history below).

Deployer / saver / RVM id: `0xbcFe81358b53f7d9Bf2A5eF6c0D03B7f447651A1`
Callback proxy (Base Sepolia): `0x476F44b11F5C942c58f4c8E3d0300E5710743585`

## Trigger transactions already sent

| # | Action | Chain | Tx |
| --- | --- | --- | --- |
| 1 | lREACT faucet claim (0.025 ETH → 2.5 lREACT) | Base Sepolia | `0x187085154af7a472393544ed416665f3e6d6350702e90842361a6e87c3a4d90d` |
| 2 | Pot deposit 0.002 ETH (origin event for v1) | Base Sepolia | `0xe144090a2982d25c5ca923a5dfce5ab71d7f0d16bf438a9a20539139b93cf960` |
| 3 | Pot deposit 0.0008 ETH (origin event for v2) | Base Sepolia | `0x2dff26d1dd1983e2fed228ab04d8ff229470be170b41e069b933dc8be15db717` |

## Open issue — reactive loop has not fired yet (as of 25 Nov ~04:50 WIB)

**Re-poll 25 Nov ~05:03 WIB (~40 min after the last stage-1 poll, ~7h40m after
the trigger deposits): STILL SILENT — no loop fired.**

**Re-poll 25 Nov ~05:49 WIB (proactive look-back): STILL SILENT** — both executors still show creation tx only on Base Sepolia Blockscout (v1 0x7ea91641…, v2 0xc984a499…). No user message sent; next scheduled re-poll is the 10:30 WIB runonce cron.

**Re-poll #3 — 25 Nov ~08:03 WIB (~10h40m after the trigger deposits):
STILL SILENT — no loop fired.**
Verified via Base Sepolia Blockscout v2 API (public, no key):
- Executor v1 `0x59bA…8583`: tx history = creation tx only
  (`0x7ea91641…`, block 63165535, 2026-11-24T21:16:15Z). No callback tx.
  Balance 0.004 ETH (unchanged).
- Executor v2 `0x136f…2Fec`: tx history = creation tx only
  (`0xc984a499…`, block 63167372, 2026-11-24T21:22:23Z). No callback tx.
  Balance 0.0012 ETH (unchanged).
- Pot `0x5e50…87b`: tx history = creation + the 2 trigger deposits only;
  balance exactly **0.0028 ETH** (2,800,000,000,000,000 wei) — no 10%
  sweep has landed (would be 0.00308 ETH).
- Note: the first API call in this poll used `?block_number=0` and returned
  0 items — that parameter breaks the listing; the plain endpoint
  (no query params) works and is what the above is based on.
- No new trigger deposits sent (funds thin, per instruction). No user
  message sent. Next re-poll: #4 (final) at ~11:00 WIB; if still silent
  then, report to the side chat that the loop has been silent ~12h and
  the next step is asking Reactive Network's Discord/dev channels.
Verified via Base Sepolia Blockscout v2 API (public, no key):
- Executor v1 `0x59bA…8583`: tx history = creation tx only
  (`0x7ea91641…`, block 63165535, 2026-11-24T21:16:15Z). No callback tx.
- Executor v2 `0x136f…2Fec`: tx history = creation tx only
  (`0xc984a499…`, block 63167372, 2026-11-24T21:22:23Z). No callback tx.
- Pot `0x5e50…87b`: tx history = creation + the 2 trigger deposits only;
  balance exactly **0.0028 ETH** (2,800,000,000,000,000 wei, last updated
  block 63167525) — no 10% sweep has landed (would be 0.00308 ETH).
- Lasna side could not be re-verified in this poll: direct RPC POSTs were
  policy-blocked in the polling session and Reactscan's v2 API path
  returned 404 (address page loads but is JS-rendered with no data). The
  destination-side evidence above is decisive on its own: no callback
  reached either executor, so no loop fired.
- No new trigger deposits sent (funds thin, per instruction).

**Re-poll #4 — 25 Nov ~10:45 WIB (~6h25m after the trigger deposits):
STILL ZERO deliveries — BUT ROOT CAUSE FOUND (proven via the official
Reactive MCP, https://mcp.rnk.dev/mcp — public, no auth).**
- Base Sepolia Blockscout v2: executor v1 creation tx only, 0.004 ETH;
  v2 creation tx only, 0.0012 ETH; pot creation + 2 deposits only,
  exactly 0.0028 ETH — no sweep.
- Lasna direct RPC (lasna-rpc.rnk.dev, block 9,187,346): v1
  `callbacksSent` = 0, `lastDepositAmount` = 0; v2 balance 0.5 lREACT,
  CronSweep 0.12 lREACT, unchanged; CRON100 emitting normally (10 per
  1,000 blocks); zero logs from any reactive contract in 3,000 blocks.
  Reactscan v2 API still 404.
- **v1: FILTER_MISMATCH (proven).** The constructor subscribed with
  topic2/topic3 = literal `0` instead of `REACTIVE_IGNORE`; DepositMade
  has only 2 topics, so the filter can never match. Origin block
  63165617 was sequenced into Lasna block 9166598 but NOT carried. v1
  itself is HEALTHY (debt 0, reserves 1.5 REACT, 1/1 subscription
  active) — only the filter is wrong.
- **v2 + CronSweep: REACT_REVERTED "ReactVM only" (proven).** Each DID
  react once, immediately: v2 reactive tx
  `0x1978fd0b6a34ae4f84a6f0bc0130a4b69c82570f6e3725fd874eab5c134e48a9`
  (Lasna block 9166951, 25 Nov 04:22 WIB); CronSweep
  `0x74f321acd81ba777dd467c3c637d31b8fbfc0e6910f87db993631f728ecb756a`
  (block 9167201, 04:27 WIB). Each revert was still charged ~0.0123
  REACT → debt on the OMNI system contract `0x8888…` (v2: 0.0123654
  REACT; CronSweep: 0.0123101 REACT) → BlacklistContract +
  PaymentFailure → subscriptions INACTIVE.
- **Why:** the classic architecture is retired — official docs: "Reactive
  Network no longer runs RVMs". The `vm`-detection pattern
  (`extcodesize(0xfffFfF) == 0`) is always false on Omni Lasna, so
  `require(vm, "ReactVM only")` reverts on every reaction.
- **Corrections to the stage-1 record:** (a) earlier "debt 0" checks read
  the WRONG system contract (classic `0xfffFfF` returns 0; real debt sits
  on Omni `0x8888…`); (b) earlier elapsed-time claims ("~10h40m" at
  08:03) mixed UTC/WIB — true elapsed at poll #4 is ~6h25m; (c) the
  sequencer is fine and Base Sepolia→Lasna pairing works (v2's log was
  carried within seconds of the deposit) — NO platform outage, NO Discord
  escalation needed; both causes are our code.
- **Stage-2 fix (NOT done — needs Boss's word for deploy broadcasts +
  repo push):** rewrite v2 + CronSweep on the new Omni API (`SYSTEM`
  `0x8888…`, `onlySystem`, `requestCallbackV_1_0`), fix v1's topic2/topic3
  to `REACTIVE_IGNORE`, redeploy all 3 reactive contracts + both
  executors (executor's authorized reactive address is immutable — a new
  RC address needs a new executor), fund reserves, re-test with a fresh
  deposit. The old contracts' debts (~0.0247 REACT total) need NOT be
  repaid — leave them abandoned; subscriptions are already inactive so no
  further charges accrue. No redeploy, no push, no new deposit sent in
  this run.

Verified on-chain:
- All subscriptions registered (system contracts emitted the subscription
  event in every deployment tx, on both the new system contract
  `0x8888…8888` and the classic one `0x0000…fffFfF`).
- Reactscan classifies the contracts as "Reactive contract".
- Contracts funded (v1: 1.5 lREACT reserves at `0x8888…`; v2: 0.5 lREACT
  balance; CronSweep: 0.12 lREACT balance; executors funded in ETH).
- Lasna CRON events are being emitted normally (Cron1 every block,
  30× Cron100 in the last 3,000 blocks).
- **But:** zero reactive transactions delivered to any of the three
  reactive contracts — balances and debts exactly unchanged, executor
  state untouched, across (a) the new-docs architecture, (b) the classic
  architecture, and (c) a network-native CRON subscription that needs no
  origin-chain watching.

Next steps when resuming (updated 25 Nov ~10:45 WIB — root cause PROVEN,
see re-poll #4 above; the Discord-escalation step is CLOSED, no platform
outage):
1. Stage-2 fix (needs Boss's word for the deploy broadcasts): rewrite
   AutoSaveReactiveV2 + CronSweep on the new Omni API (SYSTEM 0x8888…,
   onlySystem, requestCallbackV_1_0 — drop the retired `vm` pattern);
   fix AutoSaveReactive topic2/topic3 to REACTIVE_IGNORE; redeploy all 3
   reactive contracts + both executors (immutable authorized-reactive
   address); fund reserves (v1 already holds 1.5 REACT); re-test with a
   fresh deposit and capture the full loop for the demo video.
2. Do NOT repay the old contracts' debts (~0.0247 REACT total) — abandon
   them; subscriptions already inactive, no further charges.
3. Once one loop fires, record: origin tx (already have), reactive tx
   hash (Reactscan), callback tx hash (Base Sepolia explorer), then
   unsubscribe CronSweep (`unsubscribeCron()`) to stop its charges.

## Demo video plan (< 3 min, locally renderable)

Screen-capture style walkthrough (rendered locally, no live recording
needed):
1. (0:00–0:30) Problem + architecture diagram from README.
2. (0:30–1:20) Basescan: pot deposit tx → `DepositMade` event.
3. (1:20–2:10) Reactscan: the reactive transaction on Lasna.
4. (2:10–2:50) Basescan: callback tx → executor `SweepExecuted`, pot
   balance increased by the 10% sweep.
Render with the local HTML/Three.js or PIL pipeline used for other
projects; export MP4 ≤ 3 min.
