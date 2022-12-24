// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IBKZOpaqueAuctionInfo {
    function getAirdroppingItemsCount() external view returns (uint256);

    function getForSaleItemsCount() external view returns (uint256);

    function getFinalPrice() external view returns (uint256);

    function getAuctionState() external view returns (uint8);

    function getSigner() external view returns (address);
}