// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

/**
 * @dev Interface for a proposed NFT Creator Provenance Standard.
 *
 * A proposed standardized way to retrieve creator information for non-fungible tokens (NFTs)
 * to enable universal support for the consistant use and display of initial provenance information
 * across NFT marketplaces and ecosystem participants.
 *
 */
interface ICreatorProvenance {
    /**
     * @dev Returns the address of the token creator or creators and whether
     *      the creator has verified their provenance.
     */
    function provenanceTokenInfo(
        uint256 tokenId
    ) external view returns (address creators, bool isVerified);

    /**
     * @dev Allows the provenance of a token to be verified by the creator.
     */
    function verifyTokenProvenance(uint256 tokenId) external;
}