// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice Interface for securely interacting with Chainlink aggregators
 */
interface IOracleAdapter {
    struct Value {
        uint256 value;
        uint256 periodEnd;
    }

    /// @notice Event fired when asset's pricing source (aggregator) is updated
    event AssetSourceUpdated(address indexed asset, address indexed source);

    /// @notice Event fired when the TVL aggregator address is updated
    event TvlSourceUpdated(address indexed source);

    /**
     * @notice Set the TVL source (aggregator)
     * @param source The new TVL source (aggregator)
     */
    function emergencySetTvlSource(address source) external;

    /**
     * @notice Set an asset's price source (aggregator)
     * @param asset The asset to change the source of
     * @param source The new source (aggregator)
     */
    function emergencySetAssetSource(address asset, address source) external;

    /**
     * @notice Set multiple assets' pricing sources
     * @param assets An array of assets (tokens)
     * @param sources An array of price sources (aggregators)
     */
    function emergencySetAssetSources(
        address[] memory assets,
        address[] memory sources
    ) external;

    /**
     * @notice Retrieve the asset's price from its pricing source
     * @param asset The asset address
     * @return The price of the asset
     */
    function getAssetPrice(address asset) external view returns (uint256);

    /**
     * @notice Retrieve the deployed TVL from the TVL aggregator
     * @return The TVL
     */
    function getTvl() external view returns (uint256);
}