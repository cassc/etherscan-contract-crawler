// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MaskOn is Ownable, ERC721A {
    using Strings for uint256;
    string baseURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 max_supply
    ) ERC721A(name, symbol, max_supply, max_supply) {
        baseURI = uri;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require((totalSupply() + amount) <= collectionSize, "can not mint");
        _safeMint(to, amount);
    }

    function setBaseURI(string memory _baseURI_) external onlyOwner {
        baseURI = _baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_exists(tokenId)) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        }

        return "404";
    }
}