// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

uint8 constant STANDARD_DECIMALS = 18;
uint256 constant DENOMINATOR = 10000;
uint256 constant MAX_PERCENT = 100000;

struct PendingAsset {
    address token;
    address user;
    uint256 amount;
    uint256 releaseTime;
}

struct TestStruct {
    mapping(address => uint256) mp;
}

/**
 * @dev This is the library of common used functions in BedRock
 */
library BedRockLibrary {

}