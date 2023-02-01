// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {Authority} from "solmate/src/auth/Auth.sol";

contract CharlieAuthority is Authority {
    function canCall(
        address,
        address,
        bytes4
    ) external view override returns (bool) {
        return true;
    }
}