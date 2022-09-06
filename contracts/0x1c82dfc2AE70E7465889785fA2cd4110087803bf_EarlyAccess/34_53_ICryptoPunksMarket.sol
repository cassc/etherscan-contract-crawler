// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICryptoPunksMarket {
    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function punkIndexToAddress(uint256 punkIndex) external view returns (address);

    function transferPunk(address to, uint256 punkIndex) external;

    function buyPunk(uint256 punkIndex) external;
}