// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract GummyBear is ERC721A, Ownable {
    string  public baseURI = "ipfs://QmNwgpXNagQ4N4xwcBNNgK7UTYmgqai74TwizoYAzscvor/";
    uint256 public cost = 0.0003 ether;
    uint32 public immutable maxSupply = 5000;
    uint32 public immutable freeAmount = 3;
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("Gummy Bear", "GB") {
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

    function mint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= 20,"max 20 amount");
        require(msg.value >= (amount-freeAmount) * cost,"not enough");
        _safeMint(msg.sender, amount);
    }

    function setPrice(uint256 price) public onlyOwner {
        cost = price;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}