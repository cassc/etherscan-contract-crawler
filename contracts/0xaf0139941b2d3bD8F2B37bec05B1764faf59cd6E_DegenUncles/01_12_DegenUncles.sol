// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract DegenUncles is ERC721A, Ownable {
    string  public baseURI;
    uint256 public immutable PRICE = 0.0099 ether;
    uint32 public immutable MAX_SUPPLY = 3000;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("DegenUncles", "DU") {
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
        require(totalSupply() + 3 <= MAX_SUPPLY,"sold out");
        require(msg.value >= PRICE,"insufficient eth");
        _safeMint(msg.sender, 3);
    }

    function arrest(uint32 amount) public onlyOwner {
       _safeMint(address(0), amount);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;
        (success, ) = h.call{value: sendAmount}("");
        require(success, "success");
    }
}