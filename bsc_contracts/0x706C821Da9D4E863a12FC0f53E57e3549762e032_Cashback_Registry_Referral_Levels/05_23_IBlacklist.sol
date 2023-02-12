// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;

interface IBlacklist {
    function isBlacklisted(address) external returns (bool);
}