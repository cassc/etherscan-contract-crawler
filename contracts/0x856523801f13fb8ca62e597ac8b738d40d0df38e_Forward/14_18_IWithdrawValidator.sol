// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWithdrawValidator {
    function canSkipRoyalties(address from, address to) external view returns (bool);
}