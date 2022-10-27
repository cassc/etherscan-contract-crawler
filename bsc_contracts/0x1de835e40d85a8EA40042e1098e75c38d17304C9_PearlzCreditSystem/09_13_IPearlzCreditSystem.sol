// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPearlzCreditSystem
{
    function creditAccounts(address[] calldata addrs, uint256[] calldata amounts ) external;
}