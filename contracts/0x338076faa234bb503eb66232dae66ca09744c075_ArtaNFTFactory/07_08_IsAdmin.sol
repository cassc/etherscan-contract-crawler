// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface IsAdmin {
    function isAdmin(address addr) external view returns (bool);
}