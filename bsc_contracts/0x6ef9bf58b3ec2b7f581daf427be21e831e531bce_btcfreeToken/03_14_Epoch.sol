// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

contract Epoch {
    uint256 constant public EPOCH_PERIOD = 28800;

    uint256 constant public MULTIPLY = 1000000000;

    uint256 public lastEpoch;
    uint256 public lastEpochBlock;
    uint256 public maxepoch = 90;

    function start() internal {
        lastEpochBlock = block.number;
    }

    function updateEpoch() internal {
        uint256 epochCount = (block.number - lastEpochBlock) / EPOCH_PERIOD;
        lastEpoch += epochCount;
        lastEpochBlock += epochCount * EPOCH_PERIOD;
    }

    function getMultiplyByEpoch(uint256 epoch) public view returns(uint256) {
        if (epoch < maxepoch) {
            return 20800000;
        } else {
            return 0;
        }
    }

    function currentEpoch() public view returns(uint256) {
        uint256 epochCount = (block.number - lastEpochBlock) / EPOCH_PERIOD;
        return lastEpoch + epochCount;
    }

    function currentEpochBlock() public view returns(uint256) {
        uint256 epochCount = (block.number - lastEpochBlock) / EPOCH_PERIOD;
        return lastEpochBlock + epochCount * EPOCH_PERIOD;
    }
}