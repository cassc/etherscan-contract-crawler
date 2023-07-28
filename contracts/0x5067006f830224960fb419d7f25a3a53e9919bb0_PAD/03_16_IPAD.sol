// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

interface IPAD {
    function INITIAL_SUPPLY() external pure returns (uint);
    function MAX_SUPPLY() external pure returns (uint);
}