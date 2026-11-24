// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { LogRecord } from "./reactive/ReactiveInterfaces.sol";

/// @notice Classic Reactive subscription service (system contract at
/// 0x0000000000000000000000000000000000fffFfF on Reactive networks).
interface IClassicSystemContract {
    function subscribe(
        uint256 chainId_,
        address contract_,
        uint256 topic0_,
        uint256 topic1_,
        uint256 topic2_,
        uint256 topic3_
    ) external;

    function debt(address contract_) external view returns (uint256);
}

/// @title AutoSaveReactiveV2 — reactive contract (Reactive Lasna testnet),
/// classic Reactive architecture.
/// @notice Subscribes (on deployment, Reactive-side copy) to DepositMade
/// events from AutoSavePot on Base Sepolia. The ReactVM copy reacts to each
/// deposit by emitting a Callback event that the network delivers to the
/// AutoSaveExecutorV2 on Base Sepolia, sweeping 10% of the deposit.
/// @dev The ReactVM copy is detected by the absence of the system contract's
/// code (classic detectVm pattern). Configuration is constructor-set
/// (immutables), because ReactVM state mirrors the deployment, not later
/// Reactive-side writes. Billing: the contract holds an lREACT balance; the
/// system contract collects via pay(), and anyone can settle via coverDebt().
contract AutoSaveReactiveV2 {
    uint256 internal constant REACTIVE_IGNORE =
        0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;
    address internal constant SERVICE =
        0x0000000000000000000000000000000000fffFfF;

    uint64 internal constant CALLBACK_GAS_LIMIT = 500_000;

    /// @notice Emitted by the ReactVM copy to request a callback delivery.
    event Callback(
        uint256 indexed chain_id,
        address indexed _contract,
        uint64 indexed gas_limit,
        bytes payload
    );

    bool internal vm;

    uint256 public immutable originChainId;
    address public immutable originContract;
    uint256 public immutable depositTopic0;
    address public immutable executor;

    constructor(
        uint256 originChainId_,
        address originContract_,
        uint256 depositTopic0_,
        address executor_
    ) payable {
        originChainId = originChainId_;
        originContract = originContract_;
        depositTopic0 = depositTopic0_;
        executor = executor_;

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(0x0000000000000000000000000000000000fffFfF)
        }
        vm = size == 0;

        if (!vm) {
            IClassicSystemContract(SERVICE).subscribe(
                originChainId_,
                originContract_,
                depositTopic0_,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );
        }
    }

    /// @notice Entry point for event notifications; runs in the ReactVM copy.
    function react(LogRecord calldata log_) external {
        require(vm, "ReactVM only");
        if (log_.topic0 != depositTopic0) return;

        (uint256 amount, ) = abi.decode(log_.data, (uint256, uint256));

        bytes memory payload = abi.encodeWithSignature(
            "executeSweep(address,uint256)",
            address(0), // placeholder — replaced by the network with the RVM id
            amount
        );

        emit Callback(originChainId, executor, CALLBACK_GAS_LIMIT, payload);
    }

    /// @notice Fee collection by the system contract.
    function pay(uint256 amount_) external {
        require(msg.sender == SERVICE, "service only");
        require(address(this).balance >= amount_, "insufficient funds");
        if (amount_ > 0) {
            (bool ok, ) = payable(SERVICE).call{ value: amount_ }("");
            require(ok, "payment failed");
        }
    }

    /// @notice Settles any outstanding debt from this contract's balance.
    function coverDebt() external {
        uint256 d = IClassicSystemContract(SERVICE).debt(address(this));
        if (d > 0) {
            require(address(this).balance >= d, "insufficient funds");
            (bool ok, ) = payable(SERVICE).call{ value: d }("");
            require(ok, "payment failed");
        }
    }

    receive() external payable {}
}
