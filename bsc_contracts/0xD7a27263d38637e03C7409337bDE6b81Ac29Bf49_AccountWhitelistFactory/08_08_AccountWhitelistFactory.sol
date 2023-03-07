// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {AccountWhitelist} from "./AccountWhitelist.sol";

/**
 * Factory that deploys `AccountWhitelist` contract clones by making use of minimal proxy
 *
 * Meant to be utility class for internal usage only
 */
contract AccountWhitelistFactory {
    address private immutable _ownableAccountWhitelistPrototype;

    constructor(address ownableAccountWhitelistPrototype_) {
        _ownableAccountWhitelistPrototype = ownableAccountWhitelistPrototype_;
    }

    function deployClone() external returns (address ownableAccountWhitelist) {
        ownableAccountWhitelist = Clones.clone(_ownableAccountWhitelistPrototype);
        AccountWhitelist(ownableAccountWhitelist).initialize();
        AccountWhitelist(ownableAccountWhitelist).transferOwnership(msg.sender);
    }
}