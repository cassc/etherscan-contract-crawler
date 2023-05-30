// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HewerBox is Ownable, ERC721Enumerable {
    uint public constant MAX_NUM_OF_BOXES = 501;
    string public baseUri;

    constructor(string memory uri) ERC721("HewerBox", "HB") {
        setBaseURI(uri);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseUri = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function batchMintHewerBox(address [] memory _hewers) public onlyOwner {
        uint total = totalSupply();

        require(total < MAX_NUM_OF_BOXES, "Cannot exceed maximum supply");

        for (uint i = 1; i <= _hewers.length; i++) {
            _safeMint(_hewers[i - 1], i + total);
        }
    }
}