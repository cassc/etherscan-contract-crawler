// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract AscendingBeyondClouds is ERC721A, Ownable {
    string  public baseURI = "ipfs://QmY7AHYZ5CnSQwjQ79RYoGtdCKCsnNemFTbiSQiB6Sokth/";

    uint256 public mintPrice = 0.001 ether;
    uint32 public prioritizedMintSupply = 1000;
    uint32 public prioritizedMintFreeTxLimit = 10;
    uint32 public prioritizedMintPerTxLimit = 50;
    uint32 public immutable maxSupply = 7777;
    uint32 public immutable perTxLimit = 30;
    uint32 public freeTxLimit = 1;

    mapping(address => bool) public freeMinted;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("Ascending Beyond Clouds", "ABC") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function mint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        if (totalSupply() <= prioritizedMintSupply) {
            require(amount <= prioritizedMintPerTxLimit,"error");
            require(msg.value >= (amount-prioritizedMintFreeTxLimit) * mintPrice,"insufficient");

        }
        else
        {
            require(amount <= perTxLimit,"max 30 amount");
            require(msg.value >= (amount-freeTxLimit) * mintPrice,"insufficient");
        }
        _safeMint(msg.sender, amount);
    }

    function setPrioritizedMintParams(uint32 supply,uint32 freeLimit,uint32 perTxlimit) public onlyOwner {
        prioritizedMintSupply = supply;
        prioritizedMintFreeTxLimit = freeLimit;
        prioritizedMintPerTxLimit = perTxlimit;
    }

    function setFreeTxLimit(uint32 nFreeTxLimit) public onlyOwner {
        freeTxLimit = nFreeTxLimit;
    }

    function setPrice(uint256 nPrice) public onlyOwner {
        mintPrice = nPrice;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}