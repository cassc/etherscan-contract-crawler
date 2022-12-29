// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AIFrogs is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    // This counter is used to generate unique token IDs
    Counters.Counter private _tokenIdCounter;

    // The maximum number of tokens that can be minted
    uint256 private _maxTokens = 1000;

    // The total number of tokens that have been minted
    uint256 private _totalTokensMinted = 0;

    // The name and symbol for the token
    constructor() ERC721("AIFrogs", "AIFRG") {}

    /**
     * Mints a new token and assigns it to the given address.
     *
     * @param to The address to assign the token to.
     * @param uri The URI for the token.
     */
    function safeMint(address to, string memory uri) public onlyOwner {
        // Ensure that the maximum number of tokens has not been exceeded
        require(
            _totalTokensMinted < _maxTokens,
            "Cannot mint more than the maximum number of tokens."
        );

        // Generate a unique token ID
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Mint the token and set the URI
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _totalTokensMinted++;
    }

    /**
     * Mints multiple new tokens and assigns them to the given address.
     *
     * @param to The address to assign the tokens to.
     * @param uris The URIs for the tokens.
     * @param numTokens The number of tokens to mint.
     */
    function safeMintBulk(
        address to,
        string[] memory uris,
        uint256 numTokens
    ) public onlyOwner {
        // Ensure that the maximum number of tokens has not been exceeded
        require(
            _totalTokensMinted + numTokens <= _maxTokens,
            "Cannot mint more than the maximum number of tokens."
        );

        // Ensure that the number of URIs matches the number of tokens
        require(
            uris.length == numTokens,
            "The number of URIs must match the number of tokens."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            // Generate a unique token ID
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            // Mint the token and set the URI
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uris[i]);
            _totalTokensMinted++;
        }
    }

    /**
     * Sets the URI for a given token.
     *
     * @param tokenId The ID of the token to set the URI for.
     * @param uri The new URI for the token.
     */
    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        // Set the URI for the token
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    /**
     * Burns a token by removing it from the contract's ownership and transferring it back to the token's owner.
     *
     * @param tokenId The ID of the token to burn.
     */
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    /**
     * Returns the URI for the given token.
     *
     * @param tokenId The ID of the token to get the URI for.
     * @return URI for the token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}