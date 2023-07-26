// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/// @title VWMB
/// @author Hifi
/// @notice A collection of 10 Volkswagen Microbus NFTs.
contract VWMB is ERC721, Ownable {
    using Strings for uint256;

    /// CONSTANTS ///

    /// @dev The number of tokens in the collection.
    uint256 internal constant COLLECTION_SIZE = 10;

    /// INTERNAL STORAGE ///

    /// @dev The base token URI.
    string internal baseURI;

    constructor() ERC721("Volkswagen Microbus", "VWMB") {
        for (uint256 i = 0; i < COLLECTION_SIZE;) {
            _safeMint(msg.sender, i);
            unchecked {
                i += 1;
            }
        }
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @dev See {ERC721-tokenURI}.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory mBaseURI = _baseURI();
        return bytes(mBaseURI).length > 0 ? string(abi.encodePacked(mBaseURI, tokenId.toString())) : "";
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @dev Sets the base URI for all token IDs.
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// INTERNAL CONSTANT FUNCTIONS ///

    /// @dev See {ERC721-_baseURI}.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}