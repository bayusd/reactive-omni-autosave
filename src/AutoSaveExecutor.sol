// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/// @title AutoSaveExecutor — callback contract (Base Sepolia)
/// @notice Receives callbacks from AutoSaveReactive (delivered by the Reactive
/// callback proxy) and executes the automated action: sweeping 10% of each
/// deposit amount from its own float back into the AutoSavePot.
/// @dev Authentication follows the documented callback pattern: the caller
/// must be the chain's callback proxy, and the first payload argument —
/// overwritten by the network with the requesting reactive contract's
/// address — must match the authorized reactive contract.
/// Billing: funded via reserves through the proxy's depositTo().
contract AutoSaveExecutor {
    /// @notice Callback proxy on Base Sepolia (official docs, Origins & Destinations).
    address public immutable CALLBACK_PROXY;
    /// @notice The reactive contract authorized to trigger this executor.
    address public immutable reactiveContract;
    /// @notice The savings pot that receives the sweeps.
    address public immutable pot;

    uint256 public sweepsExecuted;
    uint256 public totalSwept;
    uint256 public lastDepositAmount;

    event SweepExecuted(
        address indexed reactive,
        uint256 depositAmount,
        uint256 sweepAmount
    );

    constructor(
        address callbackProxy_,
        address reactiveContract_,
        address pot_
    ) payable {
        CALLBACK_PROXY = callbackProxy_;
        reactiveContract = reactiveContract_;
        pot = pot_;
    }

    /// @notice Callback entry point. The first argument is a placeholder that
    /// Reactive Network replaces with the requesting reactive contract's
    /// address before delivery.
    function executeSweep(address reactive_, uint256 depositAmount_) external {
        require(msg.sender == CALLBACK_PROXY, "not callback proxy");
        require(reactive_ == reactiveContract, "unauthorized reactive");

        uint256 sweep = depositAmount_ / 10;
        sweepsExecuted += 1;
        totalSwept += sweep;
        lastDepositAmount = depositAmount_;

        if (sweep > 0 && address(this).balance >= sweep) {
            (bool ok, ) = pot.call{ value: sweep }("");
            require(ok, "sweep transfer failed");
        }

        emit SweepExecuted(reactive_, depositAmount_, sweep);
    }

    receive() external payable {}
}
