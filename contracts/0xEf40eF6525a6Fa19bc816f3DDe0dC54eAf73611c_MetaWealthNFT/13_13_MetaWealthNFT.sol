// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaWealthNFT is ERC721, Ownable {
    uint256 id;
    string baseURI;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC721(_name, _symbol) {
        baseURI = _uri;
    }

    function mint(address to) external onlyOwner {
        _safeMint(to, ++id);
    }

    function setBaseURI(string memory _new) external onlyOwner {
        baseURI = _new;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}