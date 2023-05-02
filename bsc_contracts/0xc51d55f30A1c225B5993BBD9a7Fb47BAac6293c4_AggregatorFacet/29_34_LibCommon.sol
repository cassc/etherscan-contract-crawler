// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

struct Hop {
    address addr;
    uint256 amountIn;
    bytes[] poolDataList;
    address[] path;
}