// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract AscendingBeyondClouds is ERC721A, Ownable {
    string  public baseURI = "";

    uint256 public price = 0.001 ether;
    uint32 public immutable maxSupply = 7777;
    uint32 public immutable onceSummon = 30;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("AscendingBeyondClouds", "ABC") {
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

    function summon(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= onceSummon,"max 30 summon");
        require(msg.value >= (amount-1) * price,"insufficient");
        _safeMint(msg.sender, amount);
    }

     function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
     }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;
        address h = payable(msg.sender);
        bool success;
        (success, ) = h.call{value: sendAmount}("");
        require(success, "Unsuccessful");
    }
}