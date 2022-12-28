// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct SendPointsParams {
    string dstChainName;
    uint256 quantity;
    uint gas;
    uint256 redirectFee;
}