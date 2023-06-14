// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract PepeXFlower is ERC721A, Ownable {
    string  public baseURI = "ipfs://QmQ4zjdHfk5QkGTg9yw9c3Frd26acxV4396UXFkUmr8f5Q/";

    uint256 public cost = 0.00022 ether;
    uint32 public immutable maxSupply = 5555;
    uint32 public immutable freeAmount = 3;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("PepeXFlower", "PXF") {
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

    function devMint(uint256 amount) public onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function publicMint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= 20,"max 20 amount");
        require(msg.value >= (amount-freeAmount) * cost,"not enough eth");
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