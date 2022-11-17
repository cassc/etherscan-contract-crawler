// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Interface for an NFT hook for handling royalties
/// @author Martin Wawrusch
/// @notice 
/// @dev  
/// @custom:security-contact [email protected]
interface IROJINFTHookRoyalties {

    /// @notice Calculates the royalties and returns the receiver for an NFT contract and token id
    /// @param contractAddress The address of the NFT contract
    /// @param tokenId The id of the token
    /// @param salePrice The price the token was sold at
    /// @return receiver The address of the account that is entitled to the royalties
    ///         royaltyAmount The calculated amount of royalties for this transaction
    function royaltyInfo(
        address contractAddress, 
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );

}