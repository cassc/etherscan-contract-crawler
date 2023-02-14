// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibDiamond} from "../libraries/LibDiamond.sol";

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    modifier nonReentrant() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.status != _ENTERED, "ReentrancyGuard: reentrant call");
        ds.status = _ENTERED;
        _;
        ds.status = _NOT_ENTERED;
    }
}