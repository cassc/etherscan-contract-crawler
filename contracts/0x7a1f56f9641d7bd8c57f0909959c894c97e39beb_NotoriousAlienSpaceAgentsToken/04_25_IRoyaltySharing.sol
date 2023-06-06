// SPDX-License-Identifier: MIT

/// @title Interface for IRoyaltySharing.

pragma solidity 0.8.6;

interface IRoyaltySharing {
    function deposit(
        uint256 creators,
        uint256 project,
        uint256 rewards
    ) external payable;
}