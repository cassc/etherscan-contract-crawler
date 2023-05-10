// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IRoyaltySplitter } from "./interfaces/IRoyaltySplitter.sol";

contract RoyaltyForwarder {
    IRoyaltySplitter private immutable royaltySplitter;

    constructor(IRoyaltySplitter royaltySplitter_) {
        royaltySplitter = royaltySplitter_;
    }

    receive() external payable {
        royaltySplitter.releaseRoyalty{ value: msg.value }();
    }
}