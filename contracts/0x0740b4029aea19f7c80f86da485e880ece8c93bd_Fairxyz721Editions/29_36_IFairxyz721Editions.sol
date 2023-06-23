// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

interface IFairxyz721Editions {
    event TokenRoyalty(
        uint256 indexed tokenId,
        address receiver,
        uint96 royaltyFraction
    );

    /**
     * @notice Burn Token
     * @dev Burns the token, sending it to the zero address.
     *
     * @param tokenId the ID of the token to burn
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Set Token Royalty
     * @dev updates the token royalty receiver and fraction, which overrides the edition and collection
     *
     * @param tokenId the ID of the token to update
     * @param receiver the address that should receive royalty payments
     * @param royaltyFraction the portion of the defined denominator that the receiver should be sent from a secondary sale
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 royaltyFraction
    ) external;

    /**
     * @notice Set Token Metadata URI
     * @dev updates the metadata URI for a specific token
     *
     * @param tokenId the ID of the token
     * @param uri the new URI for the token metadata
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;
}