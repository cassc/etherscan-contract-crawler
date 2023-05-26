// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract JailBreak is ERC721A, Ownable {
    string  public baseURI = "ipfs://QmctKFEb3BqVv8coaTUbiwqjUMCmgSqHNbkdFUvHQEvuKS/";

    uint256 public immutable mintPrice = 0.001 ether;
    uint32 public earlyMintSupply = 1000;
    uint32 public earlyMintFreeTxLimit = 5;
    uint32 public earlyMintPerTxLimit = 100;
    uint32 public immutable maxSupply = 6000;
    uint32 public immutable perTxLimit = 20;

    mapping(address => bool) public freeMinted;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("JailBreak", "HELL") {
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
        if (totalSupply() <= earlyMintSupply) {
            require(amount <= earlyMintPerTxLimit,"error");
            require(msg.value >= (amount-earlyMintFreeTxLimit) * mintPrice,"insufficient");

        }
        else
        {
            require(amount <= perTxLimit,"max 20 amount");
            require(msg.value >= (amount-1) * mintPrice,"insufficient");
        }
        _safeMint(msg.sender, amount);
    }

    function setEarlyMintParams(uint32 supply,uint32 freeLimit,uint32 perTxlimit) public onlyOwner {
        earlyMintSupply = supply;
        earlyMintFreeTxLimit = freeLimit;
        earlyMintPerTxLimit = perTxlimit;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}