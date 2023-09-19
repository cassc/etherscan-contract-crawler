/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3Oracle {
    function getMaxReceive(address fromToken, address toToken, uint256 fromAmount) external view returns (uint256);
    function getPrice(address base) external view returns (uint256);
    function getDec18Price(address base) external view returns(uint256);
    function getOriginalPrice(address base) external view returns (uint256 price, uint8 priceDecimal);
    function isFeasible(address base) external view returns (bool);
}