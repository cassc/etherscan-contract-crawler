// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

library Utility {
    function netPoints(uint256 i,uint256 a) public pure returns (uint256 t) {
        if (i == 1) {
            t = a * 5;
        } else if (i == 2) {
            t = a * 4;
        } else if (i == 3) {
            t = a * 3;
        } else if (i == 4) {
            t = a * 2;
        } else if (i == 5) {
            t = a;
        } else if (i == 6) {
            t = a;
        } else if (i == 7) {
            t = a * 2;
        } else if (i == 8) {
            t = a * 3;
        } else if (i == 9) {
            t = a * 4;
        } else if (i == 10) {
            t = a * 5;
        }
    }
    function checkLevelCap(uint256 level,uint256 staking) public pure returns(bool result){
        if (level == 0) {
            result = false;
        } else if (level == 1) {
            result = staking <= 3000 ether;
        } else if (level == 2) {
            result = staking <= 8000 ether;
        } else if (level == 3) {
            result = staking <= 20000 ether;
        } else if (level == 4) {
            result = staking <= 50000 ether;
        } else if (level == 5) {
            result = staking <= 500000 ether;
        }
    }

    function calBlowUpFirst(uint256 amount) public pure returns (uint256) {
        return (amount * 7) / 10;
    }

    function calBlowUpFirstLucky(
        uint256 amount
    ) public pure returns (uint256) {
        return (amount * 12) / 10;
    }
}