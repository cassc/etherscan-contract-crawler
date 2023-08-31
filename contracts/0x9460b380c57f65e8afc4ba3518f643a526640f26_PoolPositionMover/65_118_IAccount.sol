// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IAccount {
    function owner() external view returns (address);
}