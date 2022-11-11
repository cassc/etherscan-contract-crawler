// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer721} from "./OperatorFilterer721.sol";

abstract contract FlippableOperatorFilterer721 is OperatorFilterer721 {
    address constant DEFAULT_SUBSCRIPTION =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    bool public areOtherMarketplacesAllowed = false;

    constructor() OperatorFilterer721(DEFAULT_SUBSCRIPTION, true) {}

    modifier onlyIfOtherMarketplacesAllowed(address from) {
        if (!areOtherMarketplacesAllowed) {
            checkIfOtherMarketplaceAllowed(from);
        }
        _;
    }

    function checkIfOtherMarketplaceAllowed(address from)
        private
        onlyAllowedOperator(from)
    {
        // If the operator is not allowed, this will revert.
    }

    function flipBlockingState() internal {
        areOtherMarketplacesAllowed = !areOtherMarketplacesAllowed;
    }
}