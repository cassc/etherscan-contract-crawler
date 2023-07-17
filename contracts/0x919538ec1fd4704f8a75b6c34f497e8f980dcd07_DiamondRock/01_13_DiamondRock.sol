// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract DiamondRock is ERC721A, Ownable {
    string  public baseURI = "ipfs://QmaxnHH9S1KUKynBLhcauyR7wRKNcmT3hZZHiATtBjD2V1/";

    uint256 public mintPrice = 0.001 ether;
    uint32 public immutable maxSupply = 999;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("DiamondRock", "DR") {
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
        require(msg.value >= (amount-1) * mintPrice,"insufficient");
        require(amount <= 10,"max 10 amount");
        _safeMint(msg.sender, amount);
    }

    function setPrice(uint256 price) public onlyOwner{
        mintPrice = price;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}