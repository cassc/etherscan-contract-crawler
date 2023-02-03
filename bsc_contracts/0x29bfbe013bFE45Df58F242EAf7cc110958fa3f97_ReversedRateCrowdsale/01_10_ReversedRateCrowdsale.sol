// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Crowdsale.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ReversedRateCrowdsale is Crowdsale {
    using SafeMath for uint256;

    constructor(IERC20 token, uint256 rate, address payable wallet)
        Crowdsale(token, rate, wallet) {}

    // Changes the way in which ether is converted to tokens with decimals < 18
    // The rate defines how many wei a buyer pays for token unit
    function _getTokenAmount(uint256 weiAmount) internal override view returns (uint256) {
        return weiAmount.div(rate());
    }

    // Validates if weiAmount is enough to buy 1 token unit
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal override view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiAmount >= rate(), "Crowdsale: weiAmount is lower than rate");
    }
}