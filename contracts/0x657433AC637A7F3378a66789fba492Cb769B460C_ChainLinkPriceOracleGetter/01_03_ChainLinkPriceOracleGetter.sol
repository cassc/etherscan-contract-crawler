// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/chainLink/IFeedRegistry.sol";
import "../interfaces/IPriceOracleGetter.sol";

contract ChainLinkPriceOracleGetter is IPriceOracleGetter {
    uint256 public constant VERSION = 1;

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WBTC_ADDR = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant BTC_ADDR = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

    address public constant CHAINLINK_FEED_REGISTRY = 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf;

    IFeedRegistry public feedRegistry;

    constructor() {
        feedRegistry = IFeedRegistry(CHAINLINK_FEED_REGISTRY);
    }

    /**
     * @notice Get an asset's price
     * @param asset Underlying asset address
     * @return price Price of the asset
     * @return decimals Decimals of the returned price
     **/
    function getAssetPrice(address asset) external view override returns (uint256, uint256) {
        if (asset == WETH_ADDR) {
            asset = ETH_ADDR;
        } else if (asset == WBTC_ADDR) {
            asset = BTC_ADDR;
        }

        // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
        (, int256 price, , , ) = feedRegistry.latestRoundData(asset, address(840));
        uint8 decimals = feedRegistry.decimals(asset, address(840));

        return (uint256(price), uint256(decimals));
    }
}