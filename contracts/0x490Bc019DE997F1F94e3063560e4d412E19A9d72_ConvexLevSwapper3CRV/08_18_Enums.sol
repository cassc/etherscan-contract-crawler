// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/// @notice All possible removals on Curve
enum CurveRemovalType {
    oneCoin,
    balance,
    imbalance,
    none
}