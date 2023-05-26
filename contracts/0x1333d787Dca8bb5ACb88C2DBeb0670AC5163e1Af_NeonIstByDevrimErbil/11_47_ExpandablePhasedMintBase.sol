// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title ExpandablePhasedMintBase
 * @author @NiftyMike, NFT Culture
 * @dev
 * PhasedMint: An approach to a standard system of controlling mint phases.
 * Expandable: An approach to ERC721 contracts that allows multiple subtypes of tokens.
 */
abstract contract ExpandablePhasedMintBase {
    /**
     * Expandable collection requires flavorId to be passed in to retrieve pricing.
     */
    function getPublicMintPricePerNft(uint256 flavorId) external view virtual returns (uint256);
}