// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/// @title AutoSavePot — origin contract (Base Sepolia)
/// @notice A personal savings pot. Every deposit emits an event that a
/// Reactive Network contract on Lasna listens to, so a fixed share of each
/// deposit is swept automatically — set it and forget it.
contract AutoSavePot {
    event DepositMade(address indexed saver, uint256 amount, uint256 potBalance);

    uint256 public totalDeposited;
    uint256 public depositsCount;

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        totalDeposited += msg.value;
        depositsCount += 1;
        emit DepositMade(msg.sender, msg.value, totalDeposited);
    }

    /// @notice Plain transfers (e.g. reactive sweeps landing back in the pot)
    /// are accepted without emitting DepositMade, so sweeps never re-trigger.
    receive() external payable {}
}
