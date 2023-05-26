// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VestingCalculator {

    using SafeMath for uint256;

    uint256 public cliffStart;
    uint256 public cliffEnd;
    uint256 public cliffPeriod;
    uint256 public rewardPeriod;
    uint256 public numberOfRewardPeriods;

    modifier cliffSet() {
        require(cliffStart > 0, "cliffSet: Cliff has not begun");
        _;
    }

    constructor(uint256 _rewardPeriodInSeconds, uint256 _numberOfRewardPeriods, uint256 _cliffPeriodInSeconds){

        rewardPeriod = _rewardPeriodInSeconds;
        numberOfRewardPeriods = _numberOfRewardPeriods;
        cliffPeriod = _cliffPeriodInSeconds;

    }

    function setCliffStart() public virtual {
        require(cliffStart==0, "setCliffStart: cliff start time alreadt set");
        cliffStart = block.timestamp;
        cliffEnd = cliffStart + cliffPeriod;
    }

    function vestingSchedule(uint256 _totalAllocation, uint256 _timestamp) public view returns (uint256) {
        require(cliffEnd!=0, "vestingSchedule: cliffEnd not set");
        if (_timestamp < cliffEnd) {
            return 0;
        } else if (_timestamp > cliffEnd.add(numberOfRewardPeriods.mul(rewardPeriod))) {
            return _totalAllocation;
        } else {
            return _totalAllocation.mul(calculateRewardPeriod(_timestamp)).div(numberOfRewardPeriods);
        }
    }

    function calculateRewardPeriod(uint256 _timestamp) public view returns (uint256){
        if (_timestamp < cliffEnd) {
            return 0;
        } 
        else if (_timestamp > cliffEnd.add(numberOfRewardPeriods.mul(rewardPeriod))) {
            return numberOfRewardPeriods;
        } 
        else{
            uint256 adjustedStartTime = _timestamp - cliffEnd;
            return (adjustedStartTime - adjustedStartTime.mod(rewardPeriod)).div(rewardPeriod)+1;
        }
        
    }


}