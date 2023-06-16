// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract LilCrocodile is ERC721A, Ownable {
    string  public baseURI = "ipfs://QmW9vdZktAnwjP8BLTSryVGBmU24xr9TfrC8fEs98aXvCj/";

    uint256 public cost = 0.00033 ether;
    uint32 public immutable maxSupply = 5555;
    uint32 public immutable freeNum = 3;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("LilCrocodile", "LC") {
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
        require(amount <= 33,"max 33 amount");
        require(amount % 3 == 0,"must be a multiple of 3");
        require(msg.value >= ((amount-freeNum) / 3) * cost,"not enough");
        _safeMint(msg.sender, amount);
    }

    function teamMint(uint256 amount) public onlyOwner {
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