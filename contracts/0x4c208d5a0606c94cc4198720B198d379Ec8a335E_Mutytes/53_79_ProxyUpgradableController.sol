// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ProxyController } from "../ProxyController.sol";

abstract contract ProxyUpgradableController is ProxyController {
    modifier upgradable() {
        address implementation = implementation_();
        
         if (implementation == address(this)) {
            _;
        } else {
            _delegate(implementation);
        }
    }
}