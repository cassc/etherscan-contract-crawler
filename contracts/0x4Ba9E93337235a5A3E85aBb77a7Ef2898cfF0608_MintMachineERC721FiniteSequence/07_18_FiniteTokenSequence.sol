// SPDX-License-Identifier: MIT
// Copyright (c) 2021 Benjamin Bryant LLC
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @dev ERC721 token with fixed supply. Minted sequentially.
 */
abstract contract FiniteTokenSequence is ERC721Enumerable {
    // Maximum number of tokens that can be minted, defaults to 0 (eg. must be set)
    uint256 private _maximumSupply = 0;

    /**
     * @param maximumSupply_ total supply of tokens
     */
    constructor(uint256 maximumSupply_) {
        // initialize finite token sequence
        require(
            maximumSupply_ > 0,
            "Maximum token supply must be greater than 0"
        );
        _maximumSupply = maximumSupply_;
    }

    /**********************************************
     * Internal Config
     **********************************************/

    /**
     * @dev sets the total
     */
    function _setMaximumSupply(uint256 maximumSupply_) internal {
        require(
            maximumSupply_ >= totalSupply(),
            "Maximum supply cannot be less than totalSupply"
        );
        _maximumSupply = maximumSupply_;
    }

    /**********************************************
     * Internal Mint function
     **********************************************/

    /**
     * @dev Mints next tokenCount of tokens for address
     *      Requires:
     *          1. The number of tokens minted to be positive
     *          2. The number of tokens minted to be less than or equal to the available supply
     *          3. Checks for overflow error
     *
     * @param destination Destination address
     * @param tokenCount Number of tokens to mint
     */
    function _mintInSequenceToAddress(address destination, uint256 tokenCount)
        internal
    {
        uint256 tokenSupply = totalSupply(); // totalSupply() provided by ERC721Enumerable

        require(tokenCount > 0, "tokenCount must be greater than zero");
        require(tokenSupply + tokenCount > tokenSupply, "overflow"); // not really necessary, caught by Solidity > 0.8.0
        require(
            tokenCount <= _availableSupply(),
            "tokenCount exceeds available supply"
        );

        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = tokenSupply + i;

            _safeMint(destination, tokenId);
        }
    }

    /**********************************************
     * Internal accessors functions
     **********************************************/

    /**
     * @dev Returns available supply of tokens to be minted
     */
    function _availableSupply() internal view returns (uint256) {
        uint256 tokenSupply = totalSupply();

        // clamp to zero if there is misconfiguration
        if (tokenSupply >= _maximumSupply) {
            return 0;
        }

        return _maximumSupply - tokenSupply;
    }

    /**********************************************
     * External functions
     **********************************************/

    /**
     * @dev Returns maximum supply of tokens to be minted
     */
    function maximumSupply() external view virtual returns (uint256) {
        return _maximumSupply;
    }
}