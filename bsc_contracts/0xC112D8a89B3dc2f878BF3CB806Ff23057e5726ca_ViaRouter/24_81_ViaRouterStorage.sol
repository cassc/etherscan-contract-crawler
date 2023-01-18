// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IViaRouter.sol";

abstract contract ViaRouterStorage is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IViaRouter
{
    // STORAGE

    /// @notice Address that pre-validates execution requests
    address public validator;

    /// @notice Mapping of addresses being execution adapters
    mapping(address => bool) public adapters;

    /// @notice Mapping from execution IDs to then being executed (to prevent double execution)
    mapping(bytes32 => bool) public executedId;

    /// @notice Mapping from token addresses to fee amounts collected in form of them
    mapping(address => uint256) public collectedFees;
}