// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./MintSignatureVerifier.sol";
import "./PhygitalClaimSignatureVerifier.sol";
import "./DiscountSignatureVerifier.sol";
import "./PublicSalesActivation.sol";
import "./Withdrawable.sol";

abstract contract ERC721Opensea is
    Ownable,
    AccessControl,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    MintSignatureVerifier,
    DiscountSignatureVerifier,
    PhygitalClaimSignatureVerifier,
    PublicSalesActivation,
    Withdrawable
{
    // create minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string private _contractURI;
    string private _tokenBaseURI;

    constructor(){}

    // Single minting
    function safeMint(address to, string memory uri) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // Batch minting
    function safeMintBatch(
        address to,
        string[] memory uris,
        uint256 batchSize
    ) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uris[0]);
        for (uint256 i = 1; i < batchSize; i++) {
            _tokenIdCounter.increment();
            _safeMint(to, tokenId + i);
            _setTokenURI(tokenId + i, uris[i]);
        }
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    // To support Opensea contract-level metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // To support Opensea token metadata
    // https://docs.opensea.io/docs/metadata-standards
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _tokenBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}