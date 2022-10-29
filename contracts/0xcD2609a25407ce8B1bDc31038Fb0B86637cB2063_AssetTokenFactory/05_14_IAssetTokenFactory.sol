// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/// @author Swarm Markets
/// @title IAssetToken Factory interface
/// @notice Provided interface to interact with any contract to check
/// @notice authorization to a certain transaction
interface IAssetTokenFactory {
    function isTokenEnabled(address _tokenAddress) external view returns (bool);

    function registerAssetToken(
        address _tokenAddress,
        address _issuer,
        address _guardian
    ) external;
}