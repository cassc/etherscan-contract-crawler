// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {AuctionImmutableArgs} from "./AuctionImmutableArgs.sol";
import {IAuctionConversions} from "../interfaces/IAuctionConversions.sol";

/**
 * @notice Defines some helper conversion functions for dual auctions
 */

contract AuctionConversions is IAuctionConversions, AuctionImmutableArgs {
    /**
     * @notice Transforms a price into an ask token id
     * @dev ask token ids are just the price, with the top bit equal to 1
     */
    function toAskTokenId(uint256 price) public pure returns (uint256) {
        if (price >= 2**255) revert InvalidPrice();
        // 0b10000000... | price
        // sets the top bit to 1, leaving the rest unchanged
        return price | (2**255);
    }

    /**
     * @notice Transforms a price into a bid token id
     * @dev bid token ids are just the price, with the top bit equal to 0
     */
    function toBidTokenId(uint256 price) public pure returns (uint256) {
        if (price >= 2**255) revert InvalidPrice();
        // Price is required to be less than 2**255, so we can just return it since top bit is already 0
        return price;
    }

    /**
     * @notice Checks if tokenId is a bid token id
     */
    function isBidTokenId(uint256 tokenId) public pure returns (bool) {
        // Top bit is 0
        return (tokenId >> 255) == 0;
    }

    /**
     * @notice Transforms a tokenId into a normal price
     */
    function toPrice(uint256 tokenId) public pure returns (uint256) {
        // Bit-shifting up and then back down to clear the top bit to 0
        return (tokenId << 1) >> 1;
    }

    /**
     * @notice helper to translate ask tokens to bid tokens at a given price
     * @param askTokens The number of ask tokens to calculate
     * @param price The price, denominated in bidAssetDecimals
     * @return The equivalent value of bid tokens
     */
    function askToBid(uint256 askTokens, uint256 price)
        public
        pure
        returns (uint256)
    {
        return
            FixedPointMathLib.mulDivDown(
                askTokens,
                price,
                priceDenominator()
            );
    }

    /**
     * @notice helper to translate bid tokens to ask tokens at a given price
     * @param bidTokens The number of bid tokens to calculate
     * @param price The price, denominated in bidAssetDecimals
     * @return The equivalent value of ask tokens
     */
    function bidToAsk(uint256 bidTokens, uint256 price)
        public
        pure
        returns (uint256)
    {
        if (price == 0) revert InvalidPrice();
        return
            FixedPointMathLib.mulDivDown(
                bidTokens,
                priceDenominator(),
                price
            );
    }

    /**
     * @notice determine the max of two numbers
     * @param a the first number
     * @param a the second number
     * @return the maximum of the two numbers
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @notice determine the min of two numbers
     * @param a the first number
     * @param a the second number
     * @return the minimum of the two numbers
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}