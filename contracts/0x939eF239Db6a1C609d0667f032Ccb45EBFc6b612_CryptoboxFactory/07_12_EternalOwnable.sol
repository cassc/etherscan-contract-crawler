//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
    @title EternalOwnable
    @author iMe Lab
    @notice Ownable, but the owner cannot change
 */
abstract contract EternalOwnable is Context {
    error OwnershipIsMissing();

    address private immutable _theOwner;

    constructor(address owner) {
        _theOwner = owner;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function _checkOwner() internal view {
        if (_msgSender() != _theOwner) revert OwnershipIsMissing();
    }

    function _owner() internal view returns (address) {
        return _theOwner;
    }
}