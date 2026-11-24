# Submission checklist — Reactive Omni Buildathon (DoraHacks)

Event: Reactive Omni Buildathon — track **"Set It and Forget It"**
Submission closes: **5 Dec 2026, 20:00 UTC**
Submit at: https://dorahacks.io/hackathon/reactive-omni-buildathon/detail
(Boss registered as **Jabrik78** via GitHub on 25 Nov 2026.)

## Deliverables required by the event

- [x] Public code (this repo, MIT license) — ready to push to Boss's GitHub
      `bayusd` **only with Boss's word** (do not push without it)
- [x] Contracts deployed on testnets (see below)
- [ ] Transaction hashes proving the full loop: origin event tx →
      reactive tx → destination callback tx  ← **pending: loop has not
      fired yet (see "Open issue")**
- [ ] Demo video < 3 min (plan below)
- [ ] BUIDL submission on DoraHacks before the deadline

## Deployed contracts

| Contract | Chain | Address | Deploy tx |
| --- | --- | --- | --- |
| AutoSavePot (origin) | Base Sepolia 84532 | `0x5e50bd3892Dd44e38D98e272ceE8604331bda87b` | `0xb98845a81bcb2c6375f6724451b1ab695f8f7f5c1b7c8af544bc8db132a2c885` |
| AutoSaveReactive (v1, new-docs API) | Lasna 5318007 | `0x23c42C2c27AdcDb5FC84Ff04ec6e5B7117df799D` | `0xdd37633568fc472f56cbcbc0ba7a579a4f2e7126532ee3cc21903efccf996935` |
| AutoSaveExecutor (v1) | Base Sepolia 84532 | `0x59bA7DB649EEc5763ED2f42807eAeb603DFf8583` | `0x7ea916419a31fdf4e2c12f9b4e1850685f5c584b81d5210d70ae720908ef27f2` |
| AutoSaveExecutorV2 (classic) | Base Sepolia 84532 | `0x136fe23188453B7f5a7F30E47e224E281E2C2Fec` | `0xc984a4993d5b963c83784b8856fc5a2c00dd64fd8258c2b98cda161f6dbbea23` |
| AutoSaveReactiveV2 (classic) | Lasna 5318007 | `0x9B181dC854E9670016ab3443446aa80D4435D6dC` | `0x092476d74390266fcb70d40a3669466e4ba9b9e74ce8f2428903f97d45f23a1b` |
| CronSweep (diagnostic, classic) | Lasna 5318007 | `0xa67B8428A6C02236c1540a31D49Cc7Ba605945BB` | `0x78c8940803692c49261dda9f7a47cddb371e82bcb3af59debd01940bf4b8ae91` |

Deployer / saver / RVM id: `0xbcFe81358b53f7d9Bf2A5eF6c0D03B7f447651A1`
Callback proxy (Base Sepolia): `0x476F44b11F5C942c58f4c8E3d0300E5710743585`

## Trigger transactions already sent

| # | Action | Chain | Tx |
| --- | --- | --- | --- |
| 1 | lREACT faucet claim (0.025 ETH → 2.5 lREACT) | Base Sepolia | `0x187085154af7a472393544ed416665f3e6d6350702e90842361a6e87c3a4d90d` |
| 2 | Pot deposit 0.002 ETH (origin event for v1) | Base Sepolia | `0xe144090a2982d25c5ca923a5dfce5ab71d7f0d16bf438a9a20539139b93cf960` |
| 3 | Pot deposit 0.0008 ETH (origin event for v2) | Base Sepolia | `0x2dff26d1dd1983e2fed228ab04d8ff229470be170b41e069b933dc8be15db717` |

## Open issue — reactive loop has not fired yet (as of 25 Nov ~04:50 WIB)

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

Next steps when resuming:
1. Re-poll executor state + reactive balances (delivery may simply lag on
   the testnet); check Reactscan contract pages for reactive txs.
2. If still silent, ask in the Reactive Network Discord/dev channels
   whether Lasna reactive delivery for newly deployed contracts needs an
   activation step, and whether Lasna currently pairs with Base Sepolia
   origins in both directions.
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
