// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IUbiquityFormulas {
    function durationMultiply(
        uint256 _uLP,
        uint256 _weeks,
        uint256 _multiplier
    ) external pure returns (uint256 _shares);

    function bonding(
        uint256 _shares,
        uint256 _currentShareValue,
        uint256 _targetPrice
    ) external pure returns (uint256 _uBOND);

    function redeemBonds(
        uint256 _uBOND,
        uint256 _currentShareValue,
        uint256 _targetPrice
    ) external pure returns (uint256 _uLP);

    function bondPrice(
        uint256 _totalULP,
        uint256 _totalUBOND,
        uint256 _targetPrice
    ) external pure returns (uint256 _priceUBOND);

    function ugovMultiply(uint256 _multiplier, uint256 _price)
        external
        pure
        returns (uint256 _newMultiplier);
}