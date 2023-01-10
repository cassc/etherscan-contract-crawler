// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IAuctionCollection.sol";
import "./INiftyKit.sol";

abstract contract BaseCollection is IAuctionCollection {
    INiftyKit internal _niftyKit;

    constructor(address niftyKit_) {
        _niftyKit = INiftyKit(niftyKit_);
    }
}