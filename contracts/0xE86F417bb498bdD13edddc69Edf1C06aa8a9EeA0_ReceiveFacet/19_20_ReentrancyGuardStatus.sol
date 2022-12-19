//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek

/// @dev Status enum for DiamondReentrancyGuard
enum ReentrancyGuardStatus {
    NOT_ENTERED,
    ENTERED
}