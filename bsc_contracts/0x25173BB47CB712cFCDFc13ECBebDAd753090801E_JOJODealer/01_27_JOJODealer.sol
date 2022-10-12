/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "./JOJOView.sol";
import "./JOJOExternal.sol";
import "./JOJOOperation.sol";

/// @notice Top entrance. For implementation of specific functions:
/// view functions -> JOJOView
/// external calls -> JOJOExternal
/// owner-only methods -> JOJOOperation
/// data structure -> JOJOStorage
contract JOJODealer is JOJOExternal, JOJOOperation, JOJOView {
    constructor(address _primaryAsset) JOJOStorage() {
        state.primaryAsset = _primaryAsset;
    }

    function version() external pure returns (string memory) {
        return "JOJODealer V1.0";
    }
}