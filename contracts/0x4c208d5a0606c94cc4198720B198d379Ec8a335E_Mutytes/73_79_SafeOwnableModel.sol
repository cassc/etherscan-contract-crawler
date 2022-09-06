// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { safeOwnableStorage as os } from "./SafeOwnableStorage.sol";

abstract contract SafeOwnableModel {
    function _nomineeOwner() internal view virtual returns (address) {
        return os().nomineeOwner;
    }

    function _setNomineeOwner(address nomineeOwner) internal virtual {
        os().nomineeOwner = nomineeOwner;
    }
}