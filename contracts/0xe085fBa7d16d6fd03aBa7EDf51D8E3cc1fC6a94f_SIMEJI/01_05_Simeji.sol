// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SIMEJI is ERC721A, Ownable {
    uint256 MAX_MINTS = 10;
    uint256 MAX_SUPPLY = 5000;

    string public baseURI =
        "ipfs://QmPT8zKB2crpcDeeMcogBzLcqPbFHbNtj3qW9qYAum9pKb/";

    constructor() ERC721A("Simeji", "SJ") {}

    function mint(uint256 quantity) external payable {
        require(
            quantity + _numberMinted(msg.sender) <= MAX_MINTS,
            "Exceeded the limit"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        _safeMint(msg.sender, quantity);
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
}