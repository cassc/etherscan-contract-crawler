// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// Multi-Metadata ERC-721 token.
/// Inside the contract, there are "states". Each "state" has an associated base URI.
/// The owner of a token is free to update which "state" their tokens have, meaning that they can update their NFTs to whichever
abstract contract ERC721MultiMetadata is ERC721, Ownable {
    using Strings for uint256;

    // Mapping of state to base URI strings.
    mapping(uint256 => string) public stateURI;

    // Mapping of token IDs to their selected state.
    mapping(uint256 => uint256) public tokenMetadataState;

    // solhint-disable-next-line no-empty-blocks
    constructor(string memory zeroURI) {
        stateURI[0] = zeroURI;
    }

    /// Get the base URI of a token.
    function _baseURI(uint256 tokenId) internal view returns (string memory) {
        uint256 state = tokenMetadataState[tokenId];
        return stateURI[state];
    }

    /// Set the base URI for a state.
    function setBaseURIForState(uint256 state, string calldata uri)
        external
        onlyOwner
    {
        stateURI[state] = uri;
    }

    /// Set the state for a token.
    function setTokenState(uint256 token, uint256 state) external {
        require(msg.sender == ownerOf(token), "Not owner of token");
        require(bytes(stateURI[state]).length != 0, "State not defined");

        tokenMetadataState[token] = state;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        // solhint-disable-next-line reason-string
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(_baseURI(tokenId)).length > 0
                ? string(
                    abi.encodePacked(_baseURI(tokenId), "/", tokenId.toString())
                )
                : "";
    }
}