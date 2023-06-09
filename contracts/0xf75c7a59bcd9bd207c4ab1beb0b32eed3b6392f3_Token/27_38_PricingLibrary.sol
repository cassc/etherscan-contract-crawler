// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

library PricingLibrary {
    using SafeCast for uint256;
    using Math for uint256;

    uint256 internal constant DECIMALS = type(uint32).max;

    function baseToTokens(uint256 price, uint256 totalBase) internal pure returns (uint256) {
        return (totalBase * DECIMALS) / price;
    }

    function tokensToBase(uint256 price, uint256 totalTokens) internal pure returns (uint256) {
        return (totalTokens * price) / DECIMALS;
    }

    function create(uint256 totalTokens, uint256 totalBaseValue) internal pure returns (uint112) {
        uint256 price = (totalBaseValue * DECIMALS) / totalTokens;
        return price.toUint112();
    }
}