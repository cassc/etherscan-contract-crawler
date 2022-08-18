// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RENGA is ERC721A, Ownable {
    uint256 MAX_PER_MINT = 10;
    uint256 MAX_SUPPLY = 10000;

    string public baseURI =
        "ipfs://QmPT8zKB2crpcDeeMcogBzLcqPbFHbNtj3qW9qYAum9pKb/";

    constructor() ERC721A("RENGA NFT", "RENGA") {}

    function mint(uint256 quantity) external payable {
        require(
            quantity <= MAX_PER_MINT,
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
}