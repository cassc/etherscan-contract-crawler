// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MutantEve is ERC721A, Ownable {
    string public baseURI = "ipfs://QmYxjKJFTvXeVVyN9JgTDBdM7r5EMjWpWhmU8QynSxSa2g/";

    uint256 public immutable mintPrice = 0.005 ether;
    uint32 public immutable maxSupply = 333;
    uint32 public immutable perTxLimit = 3;

    bytes32 public root;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("MutantEve By M1x", "MutantEve") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function publicMint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= perTxLimit,"max 3 amount");
        require(msg.value >= amount * mintPrice,"insufficient");
        _safeMint(msg.sender, amount);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}