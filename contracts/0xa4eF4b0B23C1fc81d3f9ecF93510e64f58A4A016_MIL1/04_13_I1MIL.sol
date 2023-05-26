// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

interface I1MIL {
    function INITIAL_SUPPLY() external view returns (uint);
    function MAX_SUPPLY() external view returns (uint);
}