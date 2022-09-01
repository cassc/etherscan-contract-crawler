// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ITokenIdentifier} from './ITokenIdentifier.sol';
import {ICurveMetaRegistry} from './ICurveMetaRegistry.sol';
import {IConvexRegistry} from './IConvexRegistry.sol';
import {IPickleJarRegistry} from './IPickleJarRegistry.sol';

/**
 * @title IPriceOracle
 * @author Babylon Finance
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {
    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);

    function getPriceNAV(address _assetOne, address _assetTwo) external view returns (uint256);

    function updateReserves(address[] memory list) external;

    function updateMaxTwapDeviation(int24 _maxTwapDeviation) external;

    function updateTokenIdentifier(ITokenIdentifier _tokenIdentifier) external;

    function updateCurveMetaRegistry(ICurveMetaRegistry _newCurveMetaRegistry) external;

    function updateConvexRegistry(IConvexRegistry _newConvexRegistry) external;

    function updatePickleRegistry(IPickleJarRegistry _newPickleRegistry) external;

    function getCompoundExchangeRate(address _asset, address _finalAsset) external view returns (uint256);

    function getCreamExchangeRate(address _asset, address _finalAsset) external view returns (uint256);
}