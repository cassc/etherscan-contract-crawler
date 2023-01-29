// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IPriceFeed} from "./interfaces/IPriceFeed.sol";
import {IGMUOracle} from "./interfaces/IGMUOracle.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ETHGMUOracle is IPriceFeed {
    using SafeMath for uint256;

    IPriceFeed public immutable ethPriceFeed;
    IGMUOracle public immutable gmuOracle;

    uint256 public constant TARGET_DIGITS = 18;
    uint256 public lastGoodPrice;

    constructor(address _ethPriceFeed, address _gmuOracle) {
        ethPriceFeed = IPriceFeed(_ethPriceFeed);
        gmuOracle = IGMUOracle(_gmuOracle);
    }

    function fetchPrice() external override returns (uint256) {
        uint256 gmuPrice = _fetchGMUPrice();
        uint256 ethPrice = ethPriceFeed.fetchPrice();
        lastGoodPrice = (ethPrice.mul(10**TARGET_DIGITS).div(gmuPrice));
        emit LastGoodPriceUpdated(lastGoodPrice);
        return lastGoodPrice;
    }

    function _scalePriceByDigits(uint256 _price, uint256 _answerDigits)
        internal
        pure
        returns (uint256)
    {
        // Convert the price returned by the oracle to an 18-digit decimal for use.
        uint256 price;
        if (_answerDigits >= TARGET_DIGITS) {
            // Scale the returned price value down to Liquity's target precision
            price = _price.div(10**(_answerDigits - TARGET_DIGITS));
        } else if (_answerDigits < TARGET_DIGITS) {
            // Scale the returned price value up to Liquity's target precision
            price = _price.mul(10**(TARGET_DIGITS - _answerDigits));
        }
        return price;
    }

    function _fetchGMUPrice() internal returns (uint256) {
        uint256 price = gmuOracle.fetchPrice();
        uint256 precision = gmuOracle.getDecimalPercision();
        return _scalePriceByDigits(price, precision);
    }

    function getDecimalPercision() external pure override returns (uint256) {
        return TARGET_DIGITS;
    }
}