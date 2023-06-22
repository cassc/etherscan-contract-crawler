// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Interface for Funnel Factory
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IFunnelFactory {
    /// ==== Factory Errors =====

    /// Error thrown when funnel is not deployed
    error FunnelNotDeployed();

    /// Error thrown when funnel is already deployed.
    error FunnelAlreadyDeployed();

    /// @notice Event emitted when the funnel contract is deployed
    /// @param tokenAddress of the base token (indexed)
    /// @param funnelAddress of the deployed funnel contract (indexed)
    event DeployedFunnel(address indexed tokenAddress, address indexed funnelAddress);

    /// @notice Deploys a new Funnel contract
    /// @param _tokenAddress The address of the token
    /// @return _funnelAddress The address of the deployed Funnel contract
    /// @dev Throws if `_tokenAddress` has already been deployed
    function deployFunnelForToken(address _tokenAddress) external returns (address _funnelAddress);

    /// @notice Retrieves the Funnel contract address for a given token address
    /// @param _tokenAddress The address of the token
    /// @return _funnelAddress The address of the deployed Funnel contract
    /// @dev Reverts with FunnelNotDeployed if `_tokenAddress` has not been deployed
    function getFunnelForToken(address _tokenAddress) external view returns (address _funnelAddress);

    /// @notice Checks if a given address is a deployed Funnel contract
    /// @param _funnelAddress The address that you want to query
    /// @return true if contract address is a deployed Funnel contract
    function isFunnel(address _funnelAddress) external view returns (bool);
}