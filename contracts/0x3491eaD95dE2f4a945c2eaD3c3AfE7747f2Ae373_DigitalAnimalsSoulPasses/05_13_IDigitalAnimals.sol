// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDigitalAnimals {
    function mintedAllSales(address operator) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
}