// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IVestable } from "./IVestable.sol";

contract InteractsWithVestable {
    function _checkSupportsVestableInterface(address vestable) internal returns (bool) {
        try IVestable(vestable).supportsVestableInterface() returns (bool retval) {
            return retval;
        } catch {
            return false;
        }
    }
}