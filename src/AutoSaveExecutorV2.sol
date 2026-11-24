// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/// @notice Minimal view of the callback proxy's payment interface.
interface ICallbackProxy {
    function debt(address contract_) external view returns (uint256);
}

/// @title AutoSaveExecutorV2 — callback contract (Base Sepolia),
/// classic Reactive architecture.
/// @notice Receives callbacks from AutoSaveReactiveV2 (delivered by the Base
/// Sepolia callback proxy) and executes the automated action: sweeping 10%
/// of each deposit amount from its own float back into the AutoSavePot.
/// @dev Authentication follows the classic callback pattern: the caller must
/// be the chain's callback proxy, and the first payload argument — which the
/// network overwrites with the RVM id of the reactive contract (the deploying
/// account's address) — must match the expected RVM id.
/// Billing: the contract holds an ETH balance; the proxy collects callback
/// fees via pay(), and anyone can settle via coverDebt().
contract AutoSaveExecutorV2 {
    /// @notice Callback proxy on Base Sepolia (official docs).
    address public immutable CALLBACK_PROXY;
    /// @notice RVM id authorized to trigger this executor (deployer account).
    address public immutable EXPECTED_RVM_ID;
    /// @notice The savings pot that receives the sweeps.
    address public immutable pot;

    uint256 public sweepsExecuted;
    uint256 public totalSwept;
    uint256 public lastDepositAmount;

    event SweepExecuted(
        address indexed rvmId,
        uint256 depositAmount,
        uint256 sweepAmount
    );

    constructor(
        address callbackProxy_,
        address expectedRvmId_,
        address pot_
    ) payable {
        CALLBACK_PROXY = callbackProxy_;
        EXPECTED_RVM_ID = expectedRvmId_;
        pot = pot_;
    }

    /// @notice Callback entry point. The first argument is a placeholder that
    /// Reactive Network replaces with the reactive contract's RVM id before
    /// delivery.
    function executeSweep(address rvmId_, uint256 depositAmount_) external {
        require(msg.sender == CALLBACK_PROXY, "not callback proxy");
        require(rvmId_ == EXPECTED_RVM_ID, "unauthorized RVM id");

        uint256 sweep = depositAmount_ / 10;
        sweepsExecuted += 1;
        totalSwept += sweep;
        lastDepositAmount = depositAmount_;

        if (sweep > 0 && address(this).balance >= sweep) {
            (bool ok, ) = pot.call{ value: sweep }("");
            require(ok, "sweep transfer failed");
        }

        emit SweepExecuted(rvmId_, depositAmount_, sweep);
    }

    /// @notice Fee collection by the callback proxy.
    function pay(uint256 amount_) external {
        require(msg.sender == CALLBACK_PROXY, "proxy only");
        require(address(this).balance >= amount_, "insufficient funds");
        if (amount_ > 0) {
            (bool ok, ) = payable(CALLBACK_PROXY).call{ value: amount_ }("");
            require(ok, "payment failed");
        }
    }

    /// @notice Settles any outstanding debt from this contract's balance.
    function coverDebt() external {
        uint256 d = ICallbackProxy(CALLBACK_PROXY).debt(address(this));
        if (d > 0) {
            require(address(this).balance >= d, "insufficient funds");
            (bool ok, ) = payable(CALLBACK_PROXY).call{ value: d }("");
            require(ok, "payment failed");
        }
    }

    receive() external payable {}
}
