// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ownableStorage as os } from "./OwnableStorage.sol";

abstract contract OwnableModel {
    function _owner() internal view virtual returns (address) {
        return os().owner;
    }

    function _transferOwnership(address newOwner) internal virtual {
        os().owner = newOwner;
    }
}