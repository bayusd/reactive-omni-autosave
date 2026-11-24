// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { ISystemContract, LogRecord } from "./reactive/ReactiveInterfaces.sol";

/// @title AutoSaveReactive — reactive contract (Reactive Lasna testnet)
/// @notice Subscribes to DepositMade events from AutoSavePot on Base Sepolia.
/// On every deposit by the configured saver it requests a callback to the
/// AutoSaveExecutor on Base Sepolia, which sweeps 10% of the deposit amount
/// back into the pot — a fully on-chain "set it and forget it" auto-save.
/// @dev Interface implemented directly from the official Reactive Network
/// documentation. Billing: this contract is funded via reserves through the
/// system contract's depositTo(); charges consume reserves first.
contract AutoSaveReactive {
    ISystemContract internal constant SYSTEM =
        ISystemContract(0x8888888888888888888888888888888888888888);

    uint64 internal constant CALLBACK_GAS_LIMIT = 500_000;

    uint256 public immutable originChainId;
    address public immutable originContract;
    uint256 public immutable depositTopic0;
    uint256 public immutable saverTopic1;

    address public owner;
    address public recipient; // AutoSaveExecutor on the destination chain
    uint256 public callbacksSent;
    uint256 public lastDepositAmount;

    event RecipientSet(address indexed recipient);
    event CallbackSent(uint256 indexed depositAmount, uint256 sweepAmount);

    constructor(
        uint256 originChainId_,
        address originContract_,
        uint256 depositTopic0_,
        uint256 saverTopic1_
    ) payable {
        owner = msg.sender;
        originChainId = originChainId_;
        originContract = originContract_;
        depositTopic0 = depositTopic0_;
        saverTopic1 = saverTopic1_;

        SYSTEM.subscribe(
            originChainId_,
            originContract_,
            depositTopic0_,
            saverTopic1_,
            0,
            0
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function setRecipient(address recipient_) external onlyOwner {
        recipient = recipient_;
        emit RecipientSet(recipient_);
    }

    /// @notice Called by the Reactive system contract for every matching log.
    function react(LogRecord memory log_) external {
        require(msg.sender == address(SYSTEM), "only system");
        if (log_.topic0 != depositTopic0) return;
        if (recipient == address(0)) return;

        (uint256 amount, ) = abi.decode(log_.data, (uint256, uint256));
        lastDepositAmount = amount;

        bytes memory payload = abi.encodeWithSignature(
            "executeSweep(address,uint256)",
            address(0), // placeholder — replaced by the network with this contract's address
            amount
        );

        SYSTEM.requestCallbackV_1_0(
            ISystemContract.CallbackConfiguration_V_1_0({
                chainId: originChainId,
                recipient: recipient,
                gasLimit: CALLBACK_GAS_LIMIT,
                payload: payload
            })
        );

        callbacksSent += 1;
        emit CallbackSent(amount, amount / 10);
    }

    /// @notice Settles outstanding debt from this contract's own balance by
    /// topping up reserves through the system contract.
    function coverDebt() external {
        uint256 d = SYSTEM.debt(address(this));
        if (d > 0) {
            SYSTEM.depositTo{ value: d }(address(this));
        }
    }

    receive() external payable {}
}
