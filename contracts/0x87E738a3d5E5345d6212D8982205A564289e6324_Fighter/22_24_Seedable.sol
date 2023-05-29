// SPDX-License-Identifier: MIT

/// @title RaidParty Helper Contract for Seedability

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

abstract contract Seedable {
    function _validateSeed(uint256 id) internal pure {
        require(id != 0, "Seedable: not seeded");
    }
}