// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPriceHandler {
    function setPrice(uint256 _usdPrice) external;
    function setPriceFeed( address _priceFeedAddress) external;
    function price() external view returns (uint256);
    function priceInUSD() external view returns (uint256);
}