// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://eips.ethereum.org/EIPS/eip-2981

/// @dev Interface for the NFT Royalty Standard
interface IERC2981 {
    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param value - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _value sale price
     */
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        returns (address receiver, uint256 royaltyAmount);
}