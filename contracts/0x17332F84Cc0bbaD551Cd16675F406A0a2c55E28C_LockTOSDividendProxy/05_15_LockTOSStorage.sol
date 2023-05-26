// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import "../libraries/LibLockTOS.sol";

contract LockTOSStorage {
    /// @dev flag for pause proxy
    bool public pauseProxy;

    /// @dev registry
    address public stakeRegistry;
    bool public migratedL2;

    uint256 public epochUnit;
    uint256 public maxTime;

    uint256 public constant MULTIPLIER = 1e18;

    address public tos;
    uint256 public lockIdCounter;
    uint256 public cumulativeEpochUnit;
    uint256 public cumulativeTOSAmount;

    uint256 internal free = 1;

    address[] public uniqueUsers;
    LibLockTOS.Point[] public pointHistory;
    mapping(uint256 => LibLockTOS.Point[]) public lockPointHistory;
    mapping(address => mapping(uint256 => LibLockTOS.LockedBalance))
        public lockedBalances;

    mapping(uint256 => LibLockTOS.LockedBalance) public allLocks;
    mapping(address => uint256[]) public userLocks;
    mapping(uint256 => int256) public slopeChanges;
    mapping(uint256 => bool) public inUse;
}