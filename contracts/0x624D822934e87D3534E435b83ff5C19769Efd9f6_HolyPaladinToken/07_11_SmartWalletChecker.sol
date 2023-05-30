// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


/// @notice Interface of the `SmartWalletChecker` contracts of the protocol
interface SmartWalletChecker {
    function check(address) external view returns (bool);
}