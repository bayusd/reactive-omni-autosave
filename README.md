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
| AutoSaveReactive | Reactive Lasna (5318007) | `0x23c42C2c27AdcDb5FC84Ff04ec6e5B7117df799D` |
| AutoSaveExecutor | Base Sepolia (84532) | `0x59bA7DB649EEc5763ED2f42807eAeb603DFf8583` |

Deployer / saver (agent EOA): `0xbcFe81358b53f7d9Bf2A5eF6c0D03B7f447651A1`

Deploy transactions (v1):

| Contract | Deploy tx |
| --- | --- |
| AutoSavePot | `0xb98845a81bcb2c6375f6724451b1ab695f8f7f5c1b7c8af544bc8db132a2c885` |
| AutoSaveReactive | `0xdd37633568fc472f56cbcbc0ba7a579a4f2e7126532ee3cc21903efccf996935` |
| AutoSaveExecutor | `0x7ea916419a31fdf4e2c12f9b4e1850685f5c584b81d5210d70ae720908ef27f2` |

A classic-API v2 pair and a CRON diagnostic contract are also deployed —
see [SUBMISSION.md](SUBMISSION.md) for the full table, trigger transactions,
and status.

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
