// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./library/UintSet.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import { ITux } from "./ITux.sol";


contract Tux is
    ITux,
    ERC721,
    ERC721URIStorage,
    ERC721Enumerable,
    ERC721Burnable
{
    using UintSet for UintSet.Set;

    uint256 private _lastTokenId;

    string private _baseTokenURI = "ipfs://";

    mapping(uint256 => address) public tokenCreators;

    mapping(address => UintSet.Set) private _creatorTokens;


    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);

        address creator = tokenCreators[tokenId];
        delete tokenCreators[tokenId];
        _creatorTokens[creator].remove(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function owner() public pure override returns (address) {
        return address(0);
    }

    function tokenCreator(uint256 tokenId) public view override returns (address) {
        return tokenCreators[tokenId];
    }

    function creatorTokens(address creator) public view override returns (uint256[] memory) {
        return _creatorTokens[creator].values();
    }

    function tokenURI(uint256 tokenId)
        public view virtual override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function mint(string memory _tokenURI)
        public
    {
        require(bytes(_tokenURI).length != 0, "Missing tokenURI");

        _lastTokenId += 1;

        uint256 tokenId = _lastTokenId;

        _safeMint(msg.sender, tokenId);

        _setTokenURI(tokenId, _tokenURI);

        _creatorTokens[msg.sender].add(tokenId);

        tokenCreators[tokenId] = msg.sender;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}