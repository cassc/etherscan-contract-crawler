/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.16;

import "CommonConstants.sol";
import "IGlobalLock.sol";
import "Math.sol";

/**
  This contract provides the number of unlocked tokens,
  and indicates if the grant has fully unlocked.
*/
abstract contract TimeLockedTokens {
    // The lockedCommon is the central contract that provisions the locked grants.
    // It also used to maintain the token global timelock.
    IGlobalLock lockedCommon;

    // The grant start time. This is the start time of the grant 4 years gradual unlock.
    // Grant can be deployed with startTime in the past or in the future.
    // The range of allowed past/future spread is defined in {CommonConstants}.
    // and validated in the constructor.
    uint256 public startTime;

    // The amount of tokens in the locked grant.
    uint256 public grantAmount;

    function initialize(uint256 grantAmount_, uint256 startTime_) internal {
        require(address(lockedCommon) == address(0), "ALREADY_INITIALIZED");
        lockedCommon = IGlobalLock(msg.sender);
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