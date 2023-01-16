// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

interface ICryptoPunks {
    function punkIndexToAddress(uint256 index)
        external
        view
        returns (address owner);

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function buyPunk(uint256 punkIndex) external payable;

    function transferPunk(address to, uint256 punkIndex) external;
}