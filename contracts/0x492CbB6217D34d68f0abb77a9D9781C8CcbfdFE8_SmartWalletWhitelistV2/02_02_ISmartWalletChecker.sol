// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface ISmartWalletChecker {
    function check(address) external view returns (bool);
}