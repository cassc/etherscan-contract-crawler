// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title ICurveMetaRegistry
 * @author Babylon Finance
 *
 * Interface for interacting with all the curve registries
 */
interface ICurveMetaRegistry {
    /* ============ Functions ============ */

    function updatePoolsList() external;

    function updateCryptoRegistries() external;

    /* ============ View Functions ============ */

    function isPool(address _poolAddress) external view returns (bool);

    function gaugeToPool(address _gaugeAddress) external view returns (address);

    function getGauge(address _pool) external view returns (address);

    function getCoinAddresses(address _pool, bool _getUnderlying) external view returns (address[8] memory);

    function getNCoins(address _pool) external view returns (uint256);

    function getLpToken(address _pool) external view returns (address);

    function getPoolFromLpToken(address _lpToken) external view returns (address);

    function getVirtualPriceFromLpToken(address _pool) external view returns (uint256);

    function isMeta(address _pool) external view returns (bool);

    function getUnderlyingAndRate(address _pool, uint256 _i) external view returns (address, uint256);

    function findBestPoolForCoins(address _fromToken, address _toToken) external view returns (address);

    function getCoinIndices(
        address _pool,
        address _fromToken,
        address _toToken
    )
        external
        view
        returns (
            uint256,
            uint256,
            bool
        );
}