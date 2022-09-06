// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HIROTO is ERC721A, Ownable {
    uint256 MAX_PER_MINT = 10;
    uint256 MAX_SUPPLY = 10000;
    uint256 FREE_MINT = 2222;
    uint256 public mintRate = 0.0089 ether;


    string public baseURI =
        "ipfs://QmPT8zKB2crpcDeeMcogBzLcqPbFHbNtj3qW9qYAum9pKb/";

    constructor() ERC721A("HIROTO NFT", "HIROTO") {}

    function mint(uint256 quantity) external payable {
        require(
            quantity <= MAX_PER_MINT,
            "Exceeded the limit"
        );
        if (totalSupply() > FREE_MINT) {
            require(msg.value >= (mintRate * quantity), "Not enough ether sent");
         }
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough tokens left"
        );
        _safeMint(msg.sender, quantity);
    }

      function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
      }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}