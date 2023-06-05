pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

/**
 * @title Model for a rational number
 *
 * @dev A number of the form p/q where q != 0
 */
struct Rational {
    uint256 p;
    uint256 q;
}