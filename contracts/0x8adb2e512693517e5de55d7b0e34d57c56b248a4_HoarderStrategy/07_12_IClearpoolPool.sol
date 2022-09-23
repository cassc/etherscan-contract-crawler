// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IClearpoolPool {
    function provide(uint256 currencyAmount) external;
    function redeem(uint256 tokens) external;
}