//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchange {
    function price() external view returns (uint256);
}