// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./APYPoolToken.sol";

contract APYPoolTokenUpgraded is APYPoolToken {
    bool public newlyAddedVariable;

    function initializeUpgrade() public override onlyAdmin {
        newlyAddedVariable = true;
    }
}