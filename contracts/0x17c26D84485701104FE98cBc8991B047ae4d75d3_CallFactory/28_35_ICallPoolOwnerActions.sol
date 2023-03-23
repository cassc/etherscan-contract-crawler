// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface ICallPoolOwnerActions {
    function collectProtocol(
        address recipient,
        uint256 amountRequested
    ) external returns (uint256 amountSent);
}