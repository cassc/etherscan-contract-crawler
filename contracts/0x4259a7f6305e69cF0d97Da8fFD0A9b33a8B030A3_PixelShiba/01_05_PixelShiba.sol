// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PixelShiba is ERC721A, Ownable {
    uint8 public maxSupply = 100;
    uint8 public maxPerTx = 1;
    uint256 public price = 0 ether;
    bool public saleOpen = false;

    constructor() ERC721A("PixelShiba", "PS") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft.ven.earth/api/pixel-shiba/metadata/";
    }

    function mint() public {
        require(msg.sender == tx.origin, "@shiba: sender not origin");
        require(totalSupply() + 1 <= maxSupply, "@shiba: supply reached");
        require(saleOpen, "@shiba: contract not live");

        _safeMint(msg.sender, 1);
    }

    function flipSale() public onlyOwner {
        saleOpen = !saleOpen;
    }
}