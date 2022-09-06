// SPDX-License-Identifier: MIT
/// @title ICryptoPunksMarket
/// @notice ICryptoPunksMarket

pragma solidity ^0.8.13;

interface ICryptoPunksMarket {
    function punkIndexToAddress(uint) external view returns(address);

    function name() external view returns (string memory);

    function punksOfferedForSale(uint id) external view returns (bool isForSale, uint punkIndex, address seller, uint minValue, address onlySellTo);

    function totalSupply() external view returns (uint);

    function decimals() external view returns (uint8);

    function imageHash() external view returns (string memory);

    function nextPunkIndexToAssign() external view returns (uint);

    function standard() external view returns (string memory);

    function balanceOf(address) external view returns (uint);

    function symbol() external view returns (string memory);

    function numberOfPunksToReserve() external view returns (uint);

    function numberOfPunksReserved() external view returns (uint);

    function punksRemainingToAssign() external view returns (uint);

    function pendingWithdrawals(address) external view returns (uint);

    function reservePunksForOwner(uint maxForThisRun) external;

    function withdraw() external;

    function buyPunk(uint id) external payable;

    function transferPunk(address to, uint id) external;

    function offerPunkForSaleToAddress(uint id, uint minSalePriceInWei, address to) external;

    function offerPunkForSale(uint id, uint minSalePriceInWei) external;

    function getPunk(uint id) external;

    function punkNoLongerForSale(uint id) external;

    function enterBidForPunk(uint punkIndex) external payable;

    function acceptBidForPunk(uint punkIndex, uint minPrice) external;

}