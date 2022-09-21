// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Royalties.sol";
import "./utils/Roles.sol";

contract CBRNFT is
    Ownable,
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
        address _marketplace,
        string memory _contractURI,
        string memory tokenURIPrefix
    ) ERC721("Clubrare", "CBR") {
        _tokenIdCounter.increment();
        baseURI = tokenURIPrefix;
        contractURI = _contractURI;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, _marketplace);
        _grantRole(TRANSFER_ROLE, _marketplace);
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
    ) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) || hasRole(TRANSFER_ROLE, _msgSender()),
            "ERC721: caller is not token owner nor approved"
        );
        _safeTransfer(from, to, tokenId, "");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setBaseURI(string memory _baseURI) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
    }

    function setContractURI(string memory _contractURI) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _contractURI;
    }

    function burn(uint256 tokenId) public override(ERC721Burnable) whenNotPaused {
        _burn(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, super.tokenURI(tokenId))) : "";
    }

    function check() public pure returns (bytes4) {
        return bytes4(keccak256("MINT_WITH_ADDRESS"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, Royalties)
        returns (bool)
    {
        return
            interfaceId == 0x80ac58cd ||
            interfaceId == 0x5b5e139f ||
            interfaceId == 0xe37243f2 ||
            interfaceId == 0x01ffc9a7 ||
            interfaceId == 0x780e9d63 ||
            interfaceId == 0x7965db0b ||
            super.supportsInterface(interfaceId);
    }
}