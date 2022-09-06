// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract BrewKillers is ERC721A, Ownable {
    string  public baseURI;
    uint256 public immutable cost = 0.009 ether;
    uint32 public immutable maxSupply = 3333;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("BrewKillers", "BK") {
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

    function mint() public payable callerIsUser{
        require(totalSupply() + 3 <= maxSupply,"sold out");
        require(msg.value >= cost,"insufficient");
        _safeMint(msg.sender, 3);
    }

    function burn(uint32 quantity) public onlyOwner {
       _safeMint(address(0), quantity);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}