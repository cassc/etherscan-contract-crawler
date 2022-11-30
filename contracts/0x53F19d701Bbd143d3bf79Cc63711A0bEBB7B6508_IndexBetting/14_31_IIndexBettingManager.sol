// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

import "lib/solmate/src/tokens/ERC20.sol";
import "./IIndexHelper.sol";
import "./IIndexRouter.sol";

interface IIndexBettingManager {
    event BettingChallengeStarted(uint32 frontRunningLockupDuration, uint256 challengeStart, uint256 challengeEnd);

    /// @notice Starts betting challenge
    /// @param _challengeDuration Duration of challenge in seconds
    /// @param _frontRunningLockupDuration Duration of lockup period
    function startBettingChallenge(uint256 _challengeDuration, uint32 _frontRunningLockupDuration) external;
}