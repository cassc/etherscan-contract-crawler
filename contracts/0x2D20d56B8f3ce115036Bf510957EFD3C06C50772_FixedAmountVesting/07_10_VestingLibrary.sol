// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";

library VestingLibrary {
    
    struct Data {
        uint64 cliffEnd;
        // uint32 in seconds = 136 years 
        uint32 vestingInterval;
    }

    function initialize(
        Data storage self,
        uint64 cliffEnd,
        uint32 vestingInterval
    ) internal {
        // cliff may have zero duration to instantaneously unlock percentage of funds
        self.cliffEnd = cliffEnd;
        self.vestingInterval = vestingInterval;
    }

    function availableInputAmount(
        Data storage self, 
        uint totalAmount, 
        uint input, 
        uint vestedAmountPerInterval, 
        uint cliffAmount
    ) internal view returns (uint) {
        // input = amount_unlocked + amount_vested
        if (block.timestamp < self.cliffEnd) {
            return 0; // no unlock or vesting yet
        }
        uint totalVested = totalAmount - cliffAmount;
        if (input == 0) {
            return _vested(self, 0, totalVested, vestedAmountPerInterval) + cliffAmount;
        } else {
            // amount_vested = input - amount_unlocked
            uint vested = input - cliffAmount;
            return _vested(self, vested, totalVested, vestedAmountPerInterval);
        }
    }

    function _vested(
        Data storage self, 
        uint vested, 
        uint totalVested, 
        uint vestedPerInterval
    ) private view returns (uint) {
        if (totalVested == vested) {
            return 0;
        }
        if (self.vestingInterval == 0) {
            // when maxVested is too small or vestingDuration is too large, vesting reward is too small to even be distributed
            return totalVested - vested;
        }
        uint lastVesting = (vested / vestedPerInterval) * self.vestingInterval + self.cliffEnd;
        uint available = ((block.timestamp - lastVesting) / self.vestingInterval) * vestedPerInterval;
        return Math.min(available, totalVested - vested);
    }
}