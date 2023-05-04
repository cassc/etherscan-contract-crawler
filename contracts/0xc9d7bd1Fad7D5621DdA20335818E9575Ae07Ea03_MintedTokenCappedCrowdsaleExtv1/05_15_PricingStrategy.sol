// SPDX-License-Identifier: MIT
/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity 0.7.6;


/**
 * Interface for defining crowdsale pricing.
 */
abstract contract PricingStrategy {

    address public tier;

    /** Interface declaration. */
    function isPricingStrategy() public pure returns (bool) {
        return true;
    }

    /** Self check if all references are correctly set.
    *
    * Checks that pricing strategy matches crowdsale parameters.
    */
    function isSane() public pure returns (bool) {
        return true;
    }

    /**
    * @dev Pricing tells if this is a presale purchase or not.  
      @return False by default, true if a presale purchaser
    */
    function isPresalePurchase() public pure returns (bool) {
        return false;
    }

    /* How many weis one token costs */
    function updateRate(uint oneTokenInCents) external virtual;

    /**
    * When somebody tries to buy tokens for X eth, calculate how many tokens they get.
    *
    *
    * @param value - What is the value of the transaction send in as wei
    * @param tokensSold - how much tokens have been sold this far
    * @param decimals - how many decimal units the token has
    * @return tokenAmount Amount of tokens the investor receives
    */
    function calculatePrice(uint value, uint tokensSold, uint decimals) external view virtual returns (uint tokenAmount);

    function oneTokenInWei(uint tokensSold, uint decimals) external view virtual returns (uint);
}