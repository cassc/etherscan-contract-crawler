// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "erc721a/contracts/ERC721A.sol";

contract Placeholder is Ownable, ERC721A {
    using Counters for Counters.Counter;

    string public baseURI;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721A("Placeholder", "P") {
        _safeMint(_msgSender(), 1);
    }

    function mint(address account, uint256 quantity) external onlyOwner {
        _safeMint(account, quantity);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}