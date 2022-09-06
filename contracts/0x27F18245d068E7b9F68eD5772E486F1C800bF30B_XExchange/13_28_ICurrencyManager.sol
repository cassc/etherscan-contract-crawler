// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurrencyManager {
    event Added(address currency);
    event Removed(address currency);

    function add(address currency) external;

    function remove(address currency) external;

    function isValid(address currency) external view returns (bool valid);
}