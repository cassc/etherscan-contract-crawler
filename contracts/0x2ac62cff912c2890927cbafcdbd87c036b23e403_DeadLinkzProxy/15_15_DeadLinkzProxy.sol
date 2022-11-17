// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {UpgradeableProxyOwnable} from "@solidstate-solidity/proxy/upgradeable/UpgradeableProxyOwnable.sol";
import {OwnableStorage} from "@solidstate-solidity/access/ownable/OwnableStorage.sol";

contract DeadLinkzProxy is UpgradeableProxyOwnable {
    constructor(address implementation) {
        _setImplementation(implementation);
        OwnableStorage.layout().owner = msg.sender;
    }

    /**
     * @dev suppress compiler warning
     */
    receive() external payable {}
}