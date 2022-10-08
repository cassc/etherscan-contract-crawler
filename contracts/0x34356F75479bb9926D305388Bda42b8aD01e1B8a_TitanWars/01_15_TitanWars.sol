// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TitanWars is ERC721, ERC721URIStorage, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    Counters.Counter private _tokenIdCounter;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
    }

    function safeMint(address to, string memory uri)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256 tokenId)
    {
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function mint(address to, string memory uri)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256 tokenId)
    {
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setTokenURI(uint256 tokenId, string memory newURI)
        public
        onlyRole(MINTER_ROLE)
    {
        require(_exists(tokenId), "ERC721: invalid token ID");
        _setTokenURI(tokenId, newURI);
    }

    // The following functions are overrides required by Solidity.
    function burn(uint256 tokenId) public override onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}