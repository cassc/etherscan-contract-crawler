// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../WittyPixels.sol";

interface IWittyPixelsToken {

    /// ===============================================================================================================
    /// --- ERC721 extensions -----------------------------------------------------------------------------------------

    event MetadataUpdate(uint256 tokenId);
    
    function baseURI() external view returns (string memory);    
    function imageURI(uint256 tokenId) external view returns (string memory);    
    function metadata(uint256 tokenId) external view returns (string memory);    
    function totalSupply() external view returns (uint256);

    
    /// ===============================================================================================================
    /// --- WittyPixels token specific methods ------------------------------------------------------------------------


    /// @notice Returns WittyPixels token charity metadata of given token.
    function getTokenCharityValues(uint256 tokenId) external view returns (address walet, uint8 percentage);

    /// @notice Returns WittyPixels token metadata of given token.
    function getTokenMetadata(uint256 tokenId) external view returns (WittyPixels.ERC721Token memory);

    /// @notice Returns status of given WittyPixels token.
    /// @dev Possible values:
    /// @dev - 0 => Unknown, not yet launched
    /// @dev - 1 => Launched: info about the corresponding WittyPixels events has been provided by the collection's owner
    /// @dev - 2 => Minting: the token is being minted, awaiting for external data to be retrieved by the Witnet Oracle.
    /// @dev - 3 => Fracionalized: the token has been minted and its ownership transfered to a WittyPixelsTokenVault contract.
    /// @dev - 4 => Acquired: token's ownership has been acquired and belongs to the WittyPixelsTokenVault no more. 
    function getTokenStatus(uint256 tokenId) external view returns (WittyPixels.ERC721TokenStatus);
    
    /// @notice Returns literal string representing current status of given WittyPixels token.
    function getTokenStatusString(uint256 tokenId) external view returns (string memory);
    
    /// @notice Returns WittyPixelsTokenVault instance bound to the given token.
    /// @dev Reverts if the token has not yet been fractionalized.
    function getTokenVault(uint256 tokenId) external view returns (ITokenVaultWitnet);
    
    /// @notice Returns the identifiers of Witnet queries involved in the minting of given token.
    /// @dev Returns zeros if the token is yet in 'Unknown' or 'Launched' status.
    function getTokenWitnetQueries(uint256 tokenId) external view returns (WittyPixels.ERC721TokenWitnetQueries memory);

    /// @notice Returns Witnet data requests involved in the the minting of given token.
    /// @dev Returns zero addresses if the token is yet in 'Unknown' or 'Launched' status.
    function getTokenWitnetRequests(uint256 _tokenId) external view returns (WittyPixels.ERC721TokenWitnetRequests memory);
    
    /// @notice Returns number of pixels within the WittyPixels Canvas of given token.
    function pixelsOf(uint256 tokenId) external view returns (uint256);

    /// @notice Returns number of pixels contributed to given WittyPixels Canvas by given address.
    /// @dev Every WittyPixels player needs to claim contribution to a WittyPixels Canvas by calling 
    /// @dev to the `redeem(bytes deeds)` method on the corresponding token's vault contract.
    function pixelsFrom(uint256 tokenId, address from) external view returns (uint256);

    /// @notice Emits MetadataUpdate event as specified by EIP-4906.
    /// @dev Only acceptable if called from token's vault and given token is 'Fractionalized' status.
    function updateMetadataFromTokenVault(uint256 tokenId) external;

    /// @notice Verifies the provided Merkle Proof matches the token's authorship's root that
    /// @notice was retrieved by the Witnet Oracle upon minting of given token. 
    /// @dev Reverts if the token has not yet been fractionalized.
    function verifyTokenAuthorship(
            uint256 tokenId,
            uint256 playerIndex,
            uint256 playerPixels,
            bytes32[] calldata authorshipProof
        ) external view returns (bool);
}