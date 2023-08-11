// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICurrencyManager {
    function addCurrency(address currency) external;

    function removeCurrency(address currency) external;

    function isCurrencyWhitelisted(address currency) external view returns (bool);
}