// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IAlphaFund {
    function buyIn(uint256 numberOfTokens, address vault) external payable;
}