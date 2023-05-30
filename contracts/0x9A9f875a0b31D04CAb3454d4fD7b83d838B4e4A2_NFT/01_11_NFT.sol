//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable {

    uint16 constant public maxSupply = 5000;
    uint8 constant public mintLimit = 40;
    uint constant public weiPrice = 80_000_000_000_000_000; // 0.08 ETH
    uint public totalSupply = 0;
    string private _baseTokenURI;

    constructor(string memory baseTokenURI) ERC721("VoxHoundz", "VOXH") {
        _baseTokenURI = baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(uint8 mintQuantity) public payable {
        require(mintQuantity >= 1, "Quantity must be at least 1");
        require(mintQuantity <= mintLimit, "Quantity must not exceed 40");
        require(mintQuantity * weiPrice == msg.value, "Ether submitted does not match price");
        require(mintQuantity + totalSupply <= maxSupply, "Quantity would exceed max supply");

        uint tokenId = totalSupply;

        for (uint8 i = 0; i < mintQuantity; i++) {
            _safeMint(msg.sender, tokenId);
            tokenId++;
        }

        totalSupply = tokenId;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance must be positive");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success == true, "Withdrawal failed");
    }

}