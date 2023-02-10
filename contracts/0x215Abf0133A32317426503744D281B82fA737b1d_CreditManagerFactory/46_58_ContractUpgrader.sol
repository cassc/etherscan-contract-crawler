// SPDX-License-Identifier: BUSL-1.1
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
pragma abicoder v2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { AddressProvider } from "../core/AddressProvider.sol";
import { ACL } from "../core/ACL.sol";

abstract contract ContractUpgrader is Ownable {
    AddressProvider public immutable addressProvider;
    address public immutable root;

    error RootSelfDestoyException();

    constructor(address _addressProvider) {
        addressProvider = AddressProvider(_addressProvider);

        root = ACL(addressProvider.getACL()).owner();
    }

    function configure() external virtual onlyOwner {
        _configure();
        _returnRootBack();
    }

    function _configure() internal virtual;

    // Will be used in case of configure() revert
    function getRootBack() external onlyOwner {
        _returnRootBack();
    }

    function _returnRootBack() internal {
        ACL acl = ACL(addressProvider.getACL()); // T:[PD-3]
        acl.transferOwnership(root);
    }

    function destoy() external onlyOwner {
        if (ACL(addressProvider.getACL()).owner() == address(this))
            revert RootSelfDestoyException();
        selfdestruct(payable(msg.sender));
    }
}