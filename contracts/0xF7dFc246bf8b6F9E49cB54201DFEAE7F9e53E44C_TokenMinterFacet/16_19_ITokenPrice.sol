// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/// @notice common struct definitions for tokens
interface ITokenPrice {

    /// @notice DIctates how the price of the token is increased post every sale
    enum PriceModifier {

        None,
        Fixed,
        Exponential,
        InverseLog

    }

    /// @notice a token price and how it changes
    struct TokenPriceData {

        // the price of the token
        uint256 price;
         // how the price is modified
        PriceModifier priceModifier;
        // only used if priceModifier is EXPONENTIAL or INVERSELOG or FIXED
        uint256 priceModifierFactor;
        // max price for the token
        uint256 maxPrice;

    }

    /// @notice get the increased price of the token
    function getIncreasedPrice() external view returns (uint256);

    /// @notice get the increased price of the token
    function getTokenPrice() external view returns (TokenPriceData memory);


}