// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenVault.sol";

interface ITokenVaultFactory {
    
    /// @notice A new token has been fractionalized from this factory.
    event Fractionalized(
        address indexed from,   // owner of the token being fractionalized
        address indexed token,  // token collection address
        uint256 tokenId,        // token id
        address tokenVault      // token vault contract just created
    );

    /// @notice Fractionalize given token by transferring ownership to new instance of ERC-20 ERC721Token Vault. 
    /// @param token Address of ERC-721 collection.
    /// @param tokenId ERC721Token identifier within that collection.
    /// @param tokenVaultSettings Extra settings to be passed when initializing the token vault contract.
    function fractionalize(
            address token,
            uint256 tokenId,
            bytes   memory tokenVaultSettings
        )
        external returns (ITokenVault);
    
    /// @notice Gets indexed token vault contract created by this factory.
    /// @dev First created vault should be assigned index 1.
    function getTokenVaultByIndex(uint256 index) external view returns (ITokenVault);
    
    /// @notice Returns token vault prototype being instantiated when fractionalizing. 
    /// @dev If destructible, it must be owned by the factory contract.
    function getTokenVaultFactoryPrototype() external view returns (ITokenVault);

    /// @notice Returns number of vaults created so far.
    function totalTokenVaults() external view returns (uint256);

}