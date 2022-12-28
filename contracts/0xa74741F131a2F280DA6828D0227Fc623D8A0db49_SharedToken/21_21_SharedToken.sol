// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SharedToken is AccessControl, ERC721, ERC721Burnable, ERC721Enumerable, ERC721URIStorage, ERC721Royalty {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdCounter;

    string private _baseTokenURI;
    
    mapping (uint256 => bytes32) public collectionURI;

    event CollectionURIMinted(address indexed account,uint256 tokenId,bytes32 collectionURI);
    event BaseURIUpdated(string previousBaseURI, string newBaseURI);

    constructor() ERC721("Carbon Credit Asset", "CCA") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }
    
    function setBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory previousBaseURI = _baseTokenURI;
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(previousBaseURI, newBaseURI);
    }

    function setDefaultRoyalty(address recipient, uint96 fraction) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(recipient, fraction);
    }

    function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address recipient, uint96 fraction) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, recipient, fraction);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl,ERC721, ERC721Enumerable, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function safeMint(address account,bytes32 cid,string memory uri, address royaltyRecipient, uint96 royaltyFraction) external onlyRole(MINTER_ROLE){
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(account, tokenId);
        _setTokenURI(tokenId, uri);

        _setTokenRoyalty(tokenId, royaltyRecipient, royaltyFraction);

        collectionURI[tokenId] = cid;
        emit CollectionURIMinted(account,tokenId,cid);
    }

    function safeStoreMint(bytes32 cid,string memory uri,address to) external onlyRole(MINTER_ROLE){
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        collectionURI[tokenId] = cid;
        emit CollectionURIMinted(to,tokenId,cid);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId,uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId,batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
    }
}