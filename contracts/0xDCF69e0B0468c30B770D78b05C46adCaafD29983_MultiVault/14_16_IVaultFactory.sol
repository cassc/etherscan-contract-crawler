// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IVaultFactory {
    function notifyUnlock(bool isCompletelyUnlocked) external;

    function lockExtended(uint256 oldUnlockTimestamp, uint256 newUnlockTimestamp) external;
}