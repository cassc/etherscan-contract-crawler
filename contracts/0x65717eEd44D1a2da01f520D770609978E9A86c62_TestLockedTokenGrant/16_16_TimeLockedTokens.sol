// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.16;

import "CommonConstants.sol";
import "LockedTokenCommon.sol";
import "Math.sol";

/**
  This contract provides the number of unlocked tokens,
  and indicates if the grant has fully unlocked.
*/
abstract contract TimeLockedTokens {
    // The lockedCommon is the central contract that provisions the locked grants.
    // It also used to maintain the token global timelock.
    TestLockedTokenCommon immutable lockedCommon;

    // The grant start time. This is the start time of the grant 4 years gradual unlock.
    // Grant can be deployed with startTime in the past or in the future.
    // The range of allowed past/future spread is defined in {CommonConstants}.
    // and validated in the constructor.
    uint256 public immutable startTime;

    // The amount of tokens in the locked grant.
    uint256 public immutable grantAmount;

    constructor(uint256 grantAmount_, uint256 startTime_) {
        lockedCommon = TestLockedTokenCommon(msg.sender);
        grantAmount = grantAmount_;
        startTime = startTime_;
    }

    /*
      Indicates whether the grant has fully unlocked.
    */
    function isGrantFullyUnlocked() public view returns (bool) {
        return block.timestamp >= startTime + GRANT_LOCKUP_PERIOD;
    }

    /*
      The number of locked tokens that were unlocked so far.
    */
    function unlockedTokens() public view returns (uint256) {
        // Before globalUnlockTime passes, The entire grant is locked.
        if (block.timestamp <= lockedCommon.globalUnlockTime()) return 0;

        uint256 cappedElapsedTime = Math.min(elapsedTime(), GRANT_LOCKUP_PERIOD);
        return (grantAmount * cappedElapsedTime) / GRANT_LOCKUP_PERIOD;
    }

    /*
      Returns the time passed (in seconds) since grant start time.
      Returns 0 if start time is in the future.
    */
    function elapsedTime() public view returns (uint256) {
        return block.timestamp > startTime ? block.timestamp - startTime : 0;
    }
}