// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/// @notice Minimal Reactive Network system-contract interface, implemented
/// directly from the published protocol documentation
/// (dev.reactive.network — Reactive Contracts / Economy pages).
/// The system contract lives at 0x8888888888888888888888888888888888888888
/// on both Reactive Mainnet and the Lasna testnet.
interface ISystemContract {
    struct CallbackConfiguration_V_1_0 {
        uint256 chainId; // destination network
        address recipient; // target contract on the destination chain
        uint64 gasLimit; // execution gas limit for the callback
        bytes payload; // ABI-encoded function call (first arg is an address placeholder)
    }

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

    function requestCallbackV_1_0(CallbackConfiguration_V_1_0 memory config_) external;

    function depositTo(address target_) external payable;

    function debt(address target_) external view returns (uint256);

    function reserves(address target_) external view returns (uint256);
}

/// @notice Log record delivered to a reactive contract's react() method,
/// as specified in the Reactive Network documentation.
struct LogRecord {
    uint256 chainId;
    address contractAddress;
    uint256 topic0;
    uint256 topic1;
    uint256 topic2;
    uint256 topic3;
    bytes data;
    uint256 blockNumber;
    uint256 opCode;
    uint256 blockHash;
    uint256 txHash;
    uint256 logIndex;
}
