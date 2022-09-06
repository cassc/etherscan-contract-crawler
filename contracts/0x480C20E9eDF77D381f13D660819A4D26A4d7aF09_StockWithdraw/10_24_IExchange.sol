// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IExchange {
    function swap(
        address, //from
        address, //to
        uint256, //amount
        uint256 //minAmount
    ) external returns (uint256);
}