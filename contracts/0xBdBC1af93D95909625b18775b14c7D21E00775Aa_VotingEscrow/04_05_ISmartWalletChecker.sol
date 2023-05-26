// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ISmartWalletChecker {
    function check(address _addr) external returns (bool);
}