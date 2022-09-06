//SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.0;

library DateHelper {
  // function min(uint a, uint b) internal pure returns (uint) {
  //   return a < b ? a : b;
  // }

  function getPhase(uint256 _activeDateTime, uint256 _interval) internal view returns (uint256) {
    unchecked {
      uint256 passedTimeInHours = (block.timestamp - _activeDateTime) / _interval;
      if( passedTimeInHours < 24) {
        return 1;
      } else if( passedTimeInHours < 48 ) {
        return 2;
      } else if( passedTimeInHours < 72 ) {
        return 3;
      } else if( passedTimeInHours < 96 ) {
        return 4;
      } else if( passedTimeInHours < 120 ) {
        return 5;
      } else if( passedTimeInHours < 144 ) {
        return 6;
      } else if( passedTimeInHours < 168 ) {
        return 7;
      } else {
        return 8;
      }
    }
  }
}