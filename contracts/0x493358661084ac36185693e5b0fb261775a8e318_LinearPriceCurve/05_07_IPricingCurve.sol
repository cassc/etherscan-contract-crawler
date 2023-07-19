//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface IPricingCurve {
    function priceAfterBuy(
        uint256 price,
        uint256 delta,
        uint256 fee
    ) external view returns (uint256);

    function priceAfterSell(
        uint256 price,
        uint256 delta,
        uint256 fee
    ) external view returns (uint256);

    function validateLpParameters(
        uint256 spotPrice,
        uint256 delta,
        uint256 fee
    ) external view;
}