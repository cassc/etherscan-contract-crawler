// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IYuGiOhCard.sol";

contract YuGiOhCard is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl, IYuGiOhCard {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_SUPPLY = 13613; // all cards

    string public baseURI;
    string public defaultTokenURI;

    constructor() ERC721("YuGiOhCard", "YGO") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        defaultTokenURI = "ipfs://QmSVJnqFF2Bm4cZzWhsQSJoidqNMKiG46pQ4z65injktML";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(address to, uint256 amount) external override onlyRole(MINTER_ROLE) {
        require(totalSupply() < MAX_SUPPLY, "YuGiOhCard: all have been minted");
        require(totalSupply() + amount <= MAX_SUPPLY, "YuGiOhCard: exceeds MAX_SUPPLY");

        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            
            _safeMint(to, tokenId);
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "YuGiOhCard: URI set of nonexistent token");
        if (bytes(baseURI).length == 0) {
            return defaultTokenURI;
        }

        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // The following functions are system manager.
    function setDefaultTokenURI(string memory newDefaultTokenUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultTokenURI = newDefaultTokenUri;
    }

    function setBaseURI(string memory newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newBaseURI;
    }
}