// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC2981 NFT Royalty Standard.
/// @dev See https://eips.ethereum.org/EIPS/eip-2981
/// @dev Note: The ERC-165 identifier for this interface is 0x2a55205a.
interface IERC2981 {
    /// @notice Called with the sale price to determine how much royalty is owed and to whom.
    /// @param tokenId The NFT asset queried for royalty information
    /// @param salePrice The sale price of the NFT asset specified by `tokenId`
    /// @return receiver Address of who should be sent the royalty payment
    /// @return royaltyAmount The royalty payment amount for `salePrice`
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}