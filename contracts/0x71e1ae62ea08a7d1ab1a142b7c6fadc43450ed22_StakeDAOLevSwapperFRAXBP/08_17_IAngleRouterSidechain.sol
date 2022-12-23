// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @notice Action types
enum ActionType {
    transfer,
    wrap,
    wrapNative,
    sweep,
    sweepNative,
    unwrap,
    unwrapNative,
    swapIn,
    swapOut,
    uniswapV3,
    oneInch,
    claimRewards,
    gaugeDeposit,
    borrower
}

/// @notice Data needed to get permits
struct PermitType {
    address token;
    address owner;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/// @title IAngleRouterSidechain
/// @author Angle Labs, Inc.
/// @notice Interface for the `AngleRouter` contract on other chains
interface IAngleRouterSidechain {
    function mixer(
        PermitType[] memory paramsPermit,
        ActionType[] memory actions,
        bytes[] calldata data
    ) external;
}