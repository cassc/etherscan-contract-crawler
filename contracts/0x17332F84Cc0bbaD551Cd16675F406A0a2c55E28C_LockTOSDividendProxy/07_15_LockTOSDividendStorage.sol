// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import "../libraries/LibLockTOSDividend.sol";

contract LockTOSDividendStorage {
    /// @dev flag for pause proxy
    bool public pauseProxy;

    /// @dev registry
    address public stakeRegistry;
    bool public migratedL2;

    uint256 public epochUnit;
    address public lockTOS;
    uint256 public genesis;
    mapping(address => LibLockTOSDividend.Distribution) public distributions;
    address[] public distributedTokens;
    uint256 internal free = 1;
}