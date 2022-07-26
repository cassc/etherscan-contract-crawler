// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IOracleAdapter} from "./IOracleAdapter.sol";

interface IOverrideOracle is IOracleAdapter {
    /**
     * @notice Event fired when asset value is set manually
     * @param asset The asset that is being overridden
     * @param value The new value used for the override
     * @param period The number of blocks the override will be active for
     * @param periodEnd The block on which the override ends
     */
    event AssetValueSet(
        address asset,
        uint256 value,
        uint256 period,
        uint256 periodEnd
    );

    /**
     * @notice Event fired when manually submitted asset value is
     * invalidated, allowing usual Chainlink pricing.
     */
    event AssetValueUnset(address asset);

    /**
     * @notice Event fired when deployed TVL is set manually
     * @param value The new value used for the override
     * @param period The number of blocks the override will be active for
     * @param periodEnd The block on which the override ends
     */
    event TvlSet(uint256 value, uint256 period, uint256 periodEnd);

    /**
     * @notice Event fired when manually submitted TVL is
     * invalidated, allowing usual Chainlink pricing.
     */
    event TvlUnset();

    /**
     * @notice Manually override the asset pricing source with a value
     * @param asset The asset that is being overriden
     * @param value asset value to return instead of from Chainlink
     * @param period length of time, in number of blocks, to use manual override
     */
    function emergencySetAssetValue(
        address asset,
        uint256 value,
        uint256 period
    ) external;

    /**
     * @notice Revoke manually set value, allowing usual Chainlink pricing
     * @param asset address of asset to price
     */
    function emergencyUnsetAssetValue(address asset) external;

    /**
     * @notice Manually override the TVL source with a value
     * @param value TVL to return instead of from Chainlink
     * @param period length of time, in number of blocks, to use manual override
     */
    function emergencySetTvl(uint256 value, uint256 period) external;

    /// @notice Revoke manually set value, allowing usual Chainlink pricing
    function emergencyUnsetTvl() external;

    /// @notice Check if TVL has active manual override
    function hasTvlOverride() external view returns (bool);

    /**
     * @notice Check if asset has active manual override
     * @param asset address of the asset
     * @return `true` if manual override is active
     */
    function hasAssetOverride(address asset) external view returns (bool);
}