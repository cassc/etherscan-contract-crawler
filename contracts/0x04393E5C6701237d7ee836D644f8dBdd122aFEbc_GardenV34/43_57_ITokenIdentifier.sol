// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ICurveMetaRegistry} from './ICurveMetaRegistry.sol';
import {IPickleJarRegistry} from './IPickleJarRegistry.sol';
import {IConvexRegistry} from './IConvexRegistry.sol';
import {IYearnVaultRegistry} from './IYearnVaultRegistry.sol';

/**
 * @title IPriceOracle
 * @author Babylon Finance
 *
 * Interface for interacting with PriceOracle
 */
interface ITokenIdentifier {
    /* ============ View Functions ============ */

    function identifyTokens(address _tokenIn, address _tokenOut)
        external
        view
        returns (
            uint8,
            uint8,
            address,
            address
        );

    function convexPools(address _pool) external view returns (bool);

    function jars(address _jar) external view returns (uint8);

    function pickleGauges(address _gauge) external view returns (bool);

    function visors(address _visor) external view returns (bool);

    function vaults(address _vault) external view returns (bool);

    function aTokenToAsset(address _aToken) external view returns (address);

    function cTokenToAsset(address _cToken) external view returns (address);

    function jarRegistry() external view returns (IPickleJarRegistry);

    function vaultRegistry() external view returns (IYearnVaultRegistry);

    function curveMetaRegistry() external view returns (ICurveMetaRegistry);

    function convexRegistry() external view returns (IConvexRegistry);

    /* ============ Functions ============ */

    function updateVisor(address[] calldata _vaults, bool[] calldata _values) external;

    function updateCurveMetaRegistry(ICurveMetaRegistry _newCurveMetaRegistry) external;

    function updateConvexRegistry(IConvexRegistry _newConvexRegistry) external;

    function updatePickleRegistry(IPickleJarRegistry _newJarRegistry) external;

    function updateYearnVaultRegistry(IYearnVaultRegistry _newYearnVaultRegistry) external;

    function refreshAAveReserves() external;

    function refreshCompoundTokens() external;

    function updateYearnVaults() external;

    function updatePickleJars() external;

    function updateConvexPools() external;

    function updateYearnVault(address[] calldata _vaults, bool[] calldata _values) external;

    function updateAavePair(address[] calldata _aaveTokens, address[] calldata _underlyings) external;

    function updateCompoundPair(address[] calldata _cTokens, address[] calldata _underlyings) external;
}