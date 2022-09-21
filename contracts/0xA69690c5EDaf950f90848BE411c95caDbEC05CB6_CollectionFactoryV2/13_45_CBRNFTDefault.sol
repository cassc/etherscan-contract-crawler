// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "./Royalties.sol";
import "./utils/Roles.sol";

contract CBRNFTDefault is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    AccessControl,
    ERC721Burnable,
    Royalties,
    Role
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public baseURI;
    string public contractURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory _contractURI,
        string memory tokenURIPrefix,
        address _admin
    ) ERC721(name, symbol) {
        baseURI = tokenURIPrefix;
        contractURI = _contractURI;
        _tokenIdCounter.increment();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        _grantRole(MINTER_ROLE, _admin);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(
        address to,
        string memory uri,
        address creator,
        uint256 value
    ) public virtual returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        if (value > 0) {
            _setTokenRoyalty(tokenId, creator, value);
        }
        return tokenId;
    }

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri,
        address creator,
        uint256 value
    ) internal returns (uint256) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        if (value > 0) {
            _setTokenRoyalty(tokenId, creator, value);
        }
        return tokenId;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) public override(ERC721Burnable) whenNotPaused {
        _burn(tokenId);
    }

    function setBaseURI(string memory _baseURI) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
    }

    function setContractURI(string memory _contractURI) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _contractURI;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, super.tokenURI(tokenId))) : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, Royalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}