// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AntiOSGenesis is ERC721A, Ownable {

    uint256 public constant MAX_SUPPLY = 101;

    constructor() ERC721A("AntiOSGenesis", "AOG") {
        _safeMint(msg.sender, 1);
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI)) : '';
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function mint(uint256 quantity) external payable {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceed max supply.");
        _safeMint(msg.sender, quantity);
    }
}