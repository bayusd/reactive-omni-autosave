# AutoSave — Set It and Forget It (Reactive Omni Buildathon)

A personal automation built on **Reactive Network**: every time you deposit
into your savings pot on Base Sepolia, 10% of the deposit is automatically
swept back into the pot by a reactive smart contract — no server, no keeper,
no manual step. Deposit once, and the automation runs forever.

Built for the **Reactive Omni Buildathon** (DoraHacks), track
**"Set It and Forget It"** (personal automations).

## How it works

```
Base Sepolia                     Reactive Lasna                 Base Sepolia
┌──────────────┐   DepositMade   ┌──────────────────┐  callback  ┌────────────────┐
│ AutoSavePot  │ ──────────────► │ AutoSaveReactive │ ─────────► │ AutoSaveExecutor│
│ (origin)     │                 │ (reactive)       │            │ (destination)   │
└──────────────┘                 └──────────────────┘            └────────────────┘
       ▲                                                              │
       └──────────────────── 10% sweep (ETH) ─────────────────────────┘
```

1. **AutoSavePot** (Base Sepolia) — a savings pot. `deposit()` emits
   `DepositMade(saver, amount, potBalance)`.
2. **AutoSaveReactive** (Reactive Lasna testnet, chain 5318007) — subscribed
   to the pot's `DepositMade` events for the owner's address. On each event
   it decodes the amount and requests a callback via the Reactive system
   contract (`requestCallbackV_1_0`).
3. **AutoSaveExecutor** (Base Sepolia) — authenticates the callback (caller
   must be the Base Sepolia callback proxy `0x476F44b1…3585`, and the
   network-injected sender must be the reactive contract), then sweeps 10%
   of the deposit amount from its float back into the pot and records the
   execution on-chain.

Plain ETH transfers into the pot do **not** emit `DepositMade`, so sweeps
landing in the pot never re-trigger the automation.

## Networks & contracts

| Contract | Chain | Address |
| --- | --- | --- |
| AutoSavePot | Base Sepolia (84532) | `0x5e50bd3892Dd44e38D98e272ceE8604331bda87b` |
| AutoSaveReactive v1.1 | Reactive Lasna (5318007) | `0x704F877130F504A45881cE494777356fEb78d30C` |
| AutoSaveExecutor v1.1 | Base Sepolia (84532) | `0xd06fBEa650d47c7339728a701C5b4fF4E4Cc4Dbf` |

Deployer / saver (agent EOA): `0xbcFe81358b53f7d9Bf2A5eF6c0D03B7f447651A1`

Deploy transactions (v1.1, stage 2 — loop verified firing, see
[SUBMISSION.md](SUBMISSION.md)):

| Contract | Deploy tx |
| --- | --- |
| AutoSavePot | `0xb98845a81bcb2c6375f6724451b1ab695f8f7f5c1b7c8af544bc8db132a2c885` |
| AutoSaveReactive v1.1 | `0x8e90d9981df51f1ffd838090965aec519fb50cada9e82c77bb11f329632d50ee` |
| AutoSaveExecutor v1.1 | `0xa5a8e1d5faff02f6fe1034642949ef80617df20961ff9df87665fa1db3e4fa5c` |

Full loop (25 Nov 2026, ~14 seconds): pot deposit
`0xc33c5d7e5f1f02493c63dfacf025c9e7858e979674dc3dca317c8db7e4d920c9` →
reactive tx
`0x34f18a01bf757965da6044759e615376eb0ed14b384c062251331d44130ebc31` →
callback tx
`0x1dcc5461a5d920cba8a65c3b172c0faf7d11d0094ba29ae1d4844934b718749a`
(10% sweep, 0.000002 ETH, landed in the pot).

A classic-API v2 pair and a CRON diagnostic contract were also deployed in
stage 1 — both retired (classic architecture blacklisted on Lasna Omni),
see [SUBMISSION.md](SUBMISSION.md) for the full history.

Funding follows the documented Reactive economy model: both the reactive
contract and the executor hold **reserves** with the system contract /
callback proxy (funded via `depositTo()`), which pay the per-execution fees.

## Build & deploy

```bash
forge build

# 1. Origin pot (Base Sepolia)
forge create src/AutoSavePot.sol:AutoSavePot \
  --rpc-url https://sepolia.base.org --private-key $PK --broadcast

# 2. Reactive contract (Lasna) — subscribes in its constructor
forge create src/AutoSaveReactive.sol:AutoSaveReactive \
  --rpc-url https://lasna-rpc.rnk.dev/ --private-key $PK --broadcast \
  --constructor-args 84532 $POT $DEPOSIT_TOPIC0 $SAVER_TOPIC1

# 3. Fund reactive reserves (Lasna system contract)
cast send 0x8888888888888888888888888888888888888888 \
  "depositTo(address)" $REACTIVE --value 1.5ether \
  --rpc-url https://lasna-rpc.rnk.dev/ --private-key $PK

# 4. Executor (Base Sepolia), funded with a small ETH float
forge create src/AutoSaveExecutor.sol:AutoSaveExecutor \
  --rpc-url https://sepolia.base.org --private-key $PK --broadcast \
  --value 0.004ether \
  --constructor-args $BASE_SEPOLIA_CALLBACK_PROXY $REACTIVE $POT

# 5. Fund executor reserves through the callback proxy
cast send $BASE_SEPOLIA_CALLBACK_PROXY "depositTo(address)" $EXECUTOR \
  --value 0.002ether --rpc-url https://sepolia.base.org --private-key $PK

# 6. Wire the recipient on the reactive contract
cast send $REACTIVE "setRecipient(address)" $EXECUTOR \
  --rpc-url https://lasna-rpc.rnk.dev/ --private-key $PK

# 7. Trigger: one deposit runs the whole loop
cast send $POT "deposit()" --value 0.002ether \
  --rpc-url https://sepolia.base.org --private-key $PK
```

## Implementation note

The contracts implement the Reactive protocol interfaces (system contract,
subscriptions, `LogRecord`, callback requests, reserves) directly from the
official documentation at dev.reactive.network — see
`src/reactive/ReactiveInterfaces.sol`.

## License

MIT
