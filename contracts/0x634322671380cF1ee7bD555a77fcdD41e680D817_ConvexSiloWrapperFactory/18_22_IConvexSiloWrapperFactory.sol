// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.12 <=0.8.13; // solhint-disable-line compiler-version

interface IConvexSiloWrapperFactory {
    /// @dev Deploys ConvexSiloWrapper. This function is permissionless, ownership of a new token
    ///     is transferred to the Silo DAO by calling `initializeSiloWrapper`.
    /// @param _poolId the Curve pool id in the Convex Booster. Curve LP token will be the underlying
    ///     token of a wrapper.
    /// @return wrapper is an address of deployed ConvexSiloWrapper
    function createConvexSiloWrapper(uint256 _poolId) external returns (address wrapper);

    /// @dev Get deployed ConvexSiloWrapper by Curve poolId. We don't allow duplicates for the same poolId.
    /// @param _poolId the Curve pool id in the Convex Booster
    function deployedWrappers(uint256 _poolId) external view returns (address);

    /// @dev Check if an address is a ConvexSiloWrapper.
    /// @param _wrapper address to check.
    function isWrapper(address _wrapper) external view returns (bool);

    /// @dev Ping library function for ConvexSiloWrapperFactory.
    function convexSiloWrapperFactoryPing() external pure returns (bytes4);
}