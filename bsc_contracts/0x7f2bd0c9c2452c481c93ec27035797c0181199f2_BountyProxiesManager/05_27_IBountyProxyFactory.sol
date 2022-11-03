// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./BountyProxy.sol";
import "./BountyPool.sol";

/// @title IBountyProxyFactory
/// @notice Deploys new proxies with CREATE2.
interface IBountyProxyFactory {
    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @notice Mapping to track all deployed proxies.
    /// @param proxy The address of the proxy to make the check for.
    function isProxy(address proxy) external view returns (bool result);

    /// @notice The release version of PRBProxy.
    /// @dev This is stored in the factory rather than the proxy to save gas for end users.
    function VERSION() external view returns (uint256);

    // /// @notice Deploys a new proxy for a given owner and returns the address of the newly created proxy
    // /// @param _projectWallet The owner of the proxy.
    // /// @return proxy The address of the newly deployed proxy contract.
    function deployBounty(
        address _beacon,
        address _projectWallet,
        bytes memory _data
    ) external returns (BountyPool proxy);
}