// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../../../common/metadata/MetadataStorage.sol";
import "../../../common/metadata/TokenMetadataStorage.sol";
import "./IERC721Metadata.sol";

/**
 * @title ERC721 - Metadata
 * @notice Provides metadata for ERC721 tokens according to standard.
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:peer-dependencies IERC721
 * @custom:provides-interfaces IERC721Metadata
 */
contract ERC721Metadata is IERC721Metadata {
    using MetadataStorage for MetadataStorage.Layout;
    using TokenMetadataStorage for TokenMetadataStorage.Layout;

    /**
     * @inheritdoc IERC721Metadata
     */
    function name() external view override returns (string memory) {
        return MetadataStorage.layout().name;
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function symbol() external view override returns (string memory) {
        return MetadataStorage.layout().symbol;
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        TokenMetadataStorage.Layout storage l = TokenMetadataStorage.layout();

        string memory _tokenIdURI = l.tokenURIs[tokenId];
        string memory _baseURI = l.baseURI;

        if (bytes(_tokenIdURI).length > 0) {
            return _tokenIdURI;
        } else if (bytes(l.fallbackURI).length > 0) {
            return l.fallbackURI;
        } else if (bytes(_baseURI).length > 0) {
            return string(abi.encodePacked(_baseURI, Strings.toString(tokenId), l.uriSuffix));
        } else {
            return "";
        }
    }
}