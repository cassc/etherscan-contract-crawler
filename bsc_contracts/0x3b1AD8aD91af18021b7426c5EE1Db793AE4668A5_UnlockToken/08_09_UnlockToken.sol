// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UnlockToken {
    address public to;
    address public token;
    uint256 public totalCount;
    uint256 public releaseTime;
    uint256 public unlockCount = 0;
    uint256 public releaseFrequency;
    uint256 public lockedTokenAmount;
    uint256 public releaseAmountPerQuarter;

    constructor(
        address token_,
        address to_,
        uint256 releaseTime_,
        uint256 lockedTokenAmount_,
        uint256 releaseFrequency_,
        uint256 totalCount_
    ) {
        to = to_;
        token = token_;
        totalCount = totalCount_;
        releaseTime = releaseTime_;
        releaseFrequency = releaseFrequency_;
        lockedTokenAmount = lockedTokenAmount_;
        releaseAmountPerQuarter = lockedTokenAmount / totalCount;
    }

    function canUnlock() public view returns (bool) {
        require(block.timestamp >= releaseTime, "Token is not unlocked yet");

        uint256 diffSecond = block.timestamp - releaseTime;
        uint currentQuarter = uint(diffSecond / releaseFrequency);

        return currentQuarter > unlockCount && currentQuarter <= totalCount;
    }

    function unlock() public {
        bool can = canUnlock();
        if (can) {
            unlockCount = unlockCount + 1;

            console.log("action", unlockCount, releaseAmountPerQuarter);

            ERC20(token).transfer(to, releaseAmountPerQuarter);
        }
    }
}