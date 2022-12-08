// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    error Reentrancy();

    modifier nonReentrant() {
        if (reentrancyStatus != 1) revert Reentrancy();

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}