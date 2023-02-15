// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc721Example is ERC721Enumerable, ReentrancyGuard, Ownable {
    string public baseURI;
    uint256 public immutable maxSupply;
    uint256 public price;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory initBaseURI_,
        uint256 maxSupply_,
        uint256 initPrice_
    ) ERC721(name_, symbol_) {
        baseURI = initBaseURI_;
        maxSupply = maxSupply_;
        price = initPrice_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(address to_, uint256 mintAmount_) external payable {
        uint256 supply = totalSupply();
        if (msg.sender != owner()) {
            require(msg.value >= price * mintAmount_, "need to send more ETH");
        }
        require(mintAmount_ > 0);
        require(supply + mintAmount_ <= maxSupply, "reached max supply");

        for (uint256 i = 0; i <= mintAmount_ - 1; i++) {
            _safeMint(to_, supply + i);
        }
    }

    function setPrice(uint256 newPrice_) public onlyOwner {
        price = newPrice_;
    }

    function setBaseURI(string memory newBaseURI_) public onlyOwner {
        baseURI = newBaseURI_;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "withdrawal failed");
    }
}