// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IPurityChecker} from "src/IPurityChecker.sol";

import {Puretea} from "puretea/Puretea.sol";

contract PurityChecker is IPurityChecker {
    // Allow non-state modifying opcodes only.
    uint256 private constant acceptedOpcodesMask = 0x600800000000000000000000ffffffffffffffff0fdf01ff67ff00013fff0fff;

    function check(address account) external view returns (bool) {
        return Puretea.check(account.code, acceptedOpcodesMask);
    }
}