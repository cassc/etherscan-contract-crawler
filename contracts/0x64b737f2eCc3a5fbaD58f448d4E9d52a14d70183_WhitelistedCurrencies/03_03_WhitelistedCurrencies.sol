// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// OZ libraries
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract WhitelistedCurrencies is Ownable {
  mapping(address => bool) public currencyWhitelist;

  event AddCurrencyToWhitelist(address indexed currency);
  event RemoveCurrencyFromWhitelist(address indexed currency);

  /**
  * @notice adds the specified currency to the list of supported currencies
  * @param currency the address of the currency to be added
  */
  function addWhitelistedCurrency(address currency) external onlyOwner {
    currencyWhitelist[currency] = true;
 
    emit AddCurrencyToWhitelist(currency);
  }

  /**
  * @notice removes the specified currency from the list of supported currencies
  * @param currency the address of the currency to be removed
  */
  function removeWhitelistedCurrency(address currency) external onlyOwner {
    currencyWhitelist[currency] = false;
    
    emit RemoveCurrencyFromWhitelist(currency);
  }

  /**
  * @notice checks if the specified currency is whitelisted
  * @param currency the address of the currency to be checked
  */
  function isCurrencyWhitelisted(address currency) external view returns (bool) {
    return currencyWhitelist[currency];
  }
}