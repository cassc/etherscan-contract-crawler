// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";

library LinearVestingLibrary {
    
    struct Data {
        uint cliffEndBlock;
        uint vestingDurationBlocks;
    }

    function initialize(
        Data storage self,
        uint cliffEndBlock,
        uint vestingDurationBlocks
    ) internal {
        // cliff may have zero duration to instantaneously unlock percentage of funds
        self.cliffEndBlock = cliffEndBlock;
        self.vestingDurationBlocks = vestingDurationBlocks;
    }

    function availableInputAmount(
        Data storage self, 
        uint totalAmount, 
        uint vestedAmount 
    ) internal view returns (uint) {
        if (block.number < self.cliffEndBlock || totalAmount == 0) {
            return 0; // no unlock or vesting yet
        }
        return _vested(self, totalAmount, vestedAmount);
    }

    function _vested(
        Data storage self, 
        uint totalAmount, 
        uint vestedAmount
    ) private view returns (uint) {
        if (totalAmount == vestedAmount) {
            return 0;
        }
        if (self.vestingDurationBlocks == 0 || block.number >= self.cliffEndBlock + self.vestingDurationBlocks) {
            return totalAmount - vestedAmount;
        }
        uint passedBlocks = block.number - self.cliffEndBlock;
        uint available = totalAmount * passedBlocks / self.vestingDurationBlocks - vestedAmount;
        return Math.min(available, totalAmount - vestedAmount);
    }
}