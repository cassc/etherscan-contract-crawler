// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./BaseURI.sol";

contract ERC721Collection is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, BaseURI {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;    

    uint256 public maxSupply = 1000;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _tokenIdCounter.increment();
    }

    function getMaxSupply() public view returns(uint256) {
        return maxSupply;
    }

    function _baseURI() internal view override(ERC721, BaseURI) returns (string memory) {
        return BaseURI._baseURI();
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment(); // TODO: use it in constructor to make collection start from 1
        _safeMint(to, tokenId);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}