// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPrice {
    function get_virtual_price() external view returns (uint256);
}