// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface ISmartWalletWhitelistV2 {
    function check(address) external view returns (bool);
}