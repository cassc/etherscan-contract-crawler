// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
@dev The interface for the price feed consumed by PriceOracle.
 */
interface IPriceFeed {
    
    /**
    @dev Query the latest price of the specified asset.
     */
    function getAssetPrice(address asset) external view returns(uint);
}

interface IChainLinkPriceProvider {
    function latestAnswer() external view returns(uint256);
}