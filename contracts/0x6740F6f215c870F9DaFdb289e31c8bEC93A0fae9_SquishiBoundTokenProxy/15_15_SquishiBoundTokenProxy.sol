// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {UpgradeableProxyOwnable} from "@solidstate-solidity/proxy/upgradeable/UpgradeableProxyOwnable.sol";
import {OwnableStorage} from "@solidstate-solidity/access/ownable/OwnableStorage.sol";

/**
 * @title SquishiBoundTokenProxy
 * @custom:website www.squishiverse.com
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Delegation proxy contract for SquishiBound Tokens.
 */
contract SquishiBoundTokenProxy is UpgradeableProxyOwnable {
    constructor(address implementation) {
        _setImplementation(implementation);
        OwnableStorage.layout().owner = msg.sender;
    }

    /**
     * @dev suppress compiler warning
     */
    receive() external payable {}
}