// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Card is ERC721, Ownable {
    string private _baseTokenURI;
    address private _packAddress;

    uint256 public totalSupply;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address packAddress
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _packAddress = packAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function updateBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function mint(address to, uint256 tokenId) public {
        require(msg.sender == _packAddress, "Card: must be called by pack address");
        _mint(to, tokenId);
        totalSupply++;
    }
}