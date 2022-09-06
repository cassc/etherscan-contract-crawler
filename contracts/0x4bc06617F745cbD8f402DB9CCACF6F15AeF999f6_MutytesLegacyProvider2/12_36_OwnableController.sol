// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Controller } from "../IERC173Controller.sol";
import { OwnableModel } from "./OwnableModel.sol";
import { AddressUtils } from "../../utils/AddressUtils.sol";

abstract contract OwnableController is IERC173Controller, OwnableModel {
    using AddressUtils for address;

    modifier onlyOwner() {
        _enforceOnlyOwner();
        _;
    }

    function Ownable_() internal virtual {
        Ownable_(msg.sender);
    }

    function Ownable_(address owner) internal virtual {
        transferOwnership_(owner);
    }

    function owner_() internal view virtual returns (address) {
        return _owner();
    }

    function transferOwnership_(address newOwner) internal virtual {
        _transferOwnership(newOwner);
        emit OwnershipTransferred(_owner(), newOwner);
    }

    function _enforceOnlyOwner() internal view virtual {
        msg.sender.enforceEquals(_owner());
    }
}