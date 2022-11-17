// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

import "lib/solmate/src/tokens/ERC20.sol";
import "./IIndexHelper.sol";
import "./IIndexRouter.sol";

interface IIndexBettingManager {
    /// @notice Starts betting challenge
    /// @param _challengeDuration Duration of challenge in seconds
    /// @param _frontRunningLockupTimestamp Amount of time before the last deposit and withdrawal
    function startBettingChallenge(uint256 _challengeDuration, uint32 _frontRunningLockupTimestamp) external;

    /// @notice Sets new epoch end timestamp
    /// @param _timestampExtension Duration to extend the end epoch
    function setEpochEnd(uint32 _timestampExtension) external;
}