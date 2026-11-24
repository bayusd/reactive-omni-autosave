// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { LogRecord } from "./reactive/ReactiveInterfaces.sol";

interface IClassicSystemContract {
    function subscribe(
        uint256 chainId_,
        address contract_,
        uint256 topic0_,
        uint256 topic1_,
        uint256 topic2_,
        uint256 topic3_
    ) external;

    function unsubscribe(
        uint256 chainId_,
        address contract_,
        uint256 topic0_,
        uint256 topic1_,
        uint256 topic2_,
        uint256 topic3_
    ) external;

    function debt(address contract_) external view returns (uint256);
}

/// @title CronSweep — diagnostic + scheduled-automation reactive contract.
/// @notice Subscribes to the Lasna CRON100 event (~every 100 blocks) emitted
/// by the legacy system contract, and on each tick requests a sweep callback
/// to the AutoSaveExecutorV2 on Base Sepolia. Proves the reactive loop with a
/// network-native trigger that needs no origin-chain event watching.
contract CronSweep {
    uint256 internal constant REACTIVE_IGNORE =
        0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;
    address internal constant SERVICE =
        0x0000000000000000000000000000000000fffFfF;
    uint256 internal constant CRON100_TOPIC0 =
        0xb49937fb8970e19fd46d48f7e3fb00d659deac0347f79cd7cb542f0fc1503c70;

    uint64 internal constant CALLBACK_GAS_LIMIT = 500_000;

    event Callback(
        uint256 indexed chain_id,
        address indexed _contract,
        uint64 indexed gas_limit,
        bytes payload
    );

    bool internal vm;

    uint256 public immutable destinationChainId;
    address public immutable executor;
    uint256 public immutable demoAmount;
    address public immutable owner;

    constructor(
        uint256 destinationChainId_,
        address executor_,
        uint256 demoAmount_
    ) payable {
        destinationChainId = destinationChainId_;
        executor = executor_;
        demoAmount = demoAmount_;
        owner = msg.sender;

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(0x0000000000000000000000000000000000fffFfF)
        }
        vm = size == 0;

        if (!vm) {
            IClassicSystemContract(SERVICE).subscribe(
                block.chainid,
                SERVICE,
                CRON100_TOPIC0,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );
        }
    }

    function react(LogRecord calldata log_) external {
        require(vm, "ReactVM only");
        if (log_.topic0 != CRON100_TOPIC0) return;

        bytes memory payload = abi.encodeWithSignature(
            "executeSweep(address,uint256)",
            address(0),
            demoAmount
        );

        emit Callback(destinationChainId, executor, CALLBACK_GAS_LIMIT, payload);
    }

    /// @notice Stops the cron subscription (Reactive-side, owner only) so the
    /// ticks — and their callback charges — stop after the diagnostic run.
    function unsubscribeCron() external {
        require(msg.sender == owner, "owner only");
        require(!vm, "Reactive side only");
        IClassicSystemContract(SERVICE).unsubscribe(
            block.chainid,
            SERVICE,
            CRON100_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
    }

    function pay(uint256 amount_) external {
        require(msg.sender == SERVICE, "service only");
        require(address(this).balance >= amount_, "insufficient funds");
        if (amount_ > 0) {
            (bool ok, ) = payable(SERVICE).call{ value: amount_ }("");
            require(ok, "payment failed");
        }
    }

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
