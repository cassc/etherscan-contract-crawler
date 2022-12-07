// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./ERC721Creator.sol";

/**
 * @title A mixin to extend the OpenZeppelin metadata implementation.
 */
abstract contract ERC721Metadata is ERC721Creator {
    using Strings for uint256;

    /**
     * @notice Emitted when the base URI used by NFTs created by this contract is updated.
     * @param baseURI The new base URI to use for all NFTs created by this contract.
     */
    event BaseURIUpdated(string baseURI);

    /**
     * @notice Returns the IPFS path to the metadata JSON file for a given NFT.
     * @param tokenId The NFT to get the CID path for.
     * @return path The IPFS path to the metadata JSON file, without the base URI prefix.
     */
    function getTokenIPFSHash(uint256 tokenId)
        public
        view
        returns (string memory path)
    {
        path = _tokenURIs[tokenId];
    }

    function updateBaseURI(string memory _baseURI) public onlyCHIZUAdmin {
        _updateBaseURI(_baseURI);
    }

    /**
     * @dev When a token is burned, remove record of it allowing that creator to re-mint the same NFT again in the future.
     */
    function _burn(uint256 tokenId) internal virtual override {
        [_tokenURIs[tokenId]];
        super._burn(tokenId);
    }

    /**
     * @dev The IPFS path should be the CID
     */
    function _setTokenIPFSHash(uint256 tokenId, string memory _tokenIPFSHash)
        internal
    {
        // 46 is the minimum length for an IPFS content hash, it may be longer if paths are used
        require(
            bytes(_tokenIPFSHash).length >= 46,
            "ERC721Metadata: Invalid IPFS path"
        );

        _setTokenURI(tokenId, _tokenIPFSHash);
    }

    function _updateBaseURI(string memory _baseURI) internal {
        _setBaseURI(_baseURI);

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[100] private __gap;
}