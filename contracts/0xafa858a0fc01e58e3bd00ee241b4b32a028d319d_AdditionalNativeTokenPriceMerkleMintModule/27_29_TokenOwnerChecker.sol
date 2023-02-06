// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IOwner} from "./IOwner.sol";

/**
 * @title TokenOwnerChecker
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Utility for use by any Module or Guard that needs to check if an address is
 * the owner of the TokenEnforceable (ERC20Club or ERC721Collective)
 */

abstract contract TokenOwnerChecker {
    /**
     * Only proceed if msg.sender owns TokenEnforceable contract
     * @param token TokenEnforceable whose owner to check
     */
    modifier onlyTokenOwner(address token) {
        _onlyTokenOwner(token);
        _;
    }

    function _onlyTokenOwner(address token) internal view {
        require(
            msg.sender == IOwner(token).owner(),
            "TokenOwnerChecker: Caller not token owner"
        );
    }
}