//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ProbablyNothing is ERC721A, Ownable, ReentrancyGuard {
    uint256 public collectionSize = 200;
    string private _baseTokenURI;

    constructor() ERC721A("Probably Nothing", "PROBNOTHING") {}

    function mintDev(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        _safeMint(msg.sender, quantity);
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}