// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IWhitelistedCurrencies {
  function isCurrencyWhitelisted(address currency) external view returns (bool);  
}