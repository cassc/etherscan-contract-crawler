//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/**
 * Represents the external interface of an ERC-721 collection.
 */
interface ICollection {
    /**
     * Mints a new token and transfers it to the receiver.
     *
     * Assigns a token id, token URI, royalty receiver and royalty numerator
     *
     * @param tokenReceiver The address that should receive the token.
     * @param tokenId The token id of the token.
     * @param tokenURI_ The token URI of the token.
     * @param royaltyReceiver The royalty receiver of the token.
     * @param royaltyNumerator The royalty numerator of the token.
     */
    function mintToken(
        address tokenReceiver,
        uint256 tokenId,
        string calldata tokenURI_,
        address royaltyReceiver,
        uint16 royaltyNumerator
    ) external;
}