//SPDX-License-Identifier: Unlicense
// Version 0.0.1

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {IOperatorFilterRegistry} from "operator-filter-registry/src/IOperatorFilterRegistry.sol";

contract MBlacklist is Context, AccessControl, Ownable {
    //----------------------------------------//
    //           Custom Errors                //
    //----------------------------------------//
    /**
     * Transfer ownership to zero address
     */
    error TransferOwnershipToZeroAddress();

    // Constants
    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address defaultAdmin_) {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);
        _transferOwnership(defaultAdmin_);

        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            OPERATOR_FILTER_REGISTRY.register(address(this));
        }
    }

    //----------------------------------------//
    //           Custom overrides             //
    //----------------------------------------//
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner_)
        public
        override(Ownable)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (newOwner_ == address(0)) {
            revert TransferOwnershipToZeroAddress();
        }
        _transferOwnership(newOwner_);
    }
}