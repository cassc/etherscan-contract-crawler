// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./base64.sol";

contract ChimneyTownDAO is ERC721Enumerable, Ownable, ReentrancyGuard {

    using Strings for uint256;

    uint256 private _currentTokenId;
    uint256 public mintPrice = 10000000000000000; // 0.01Eth
    string public imageURI = "https://ipfs.io/ipfs/QmV7zdTBvo8Rg5VtVemfjM49HPhRQA9XupF566pf2n85Gp";

    constructor() ERC721("CHIMNEY TOWN DAO", "CTD") {
        _currentTokenId = 10000;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ChimneyTownDAO: URI query for nonexistent token");

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "CHIMNEY TOWN DAO #', tokenId.toString() , '", "description": "","image": "', imageURI , '"}'))));

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    //******************************
    // public functions
    //******************************
    function mint() external nonReentrant payable {
        require(msg.value >= mintPrice, "ChimneyTownDAO: Invalid price");
         uint256 tokenId = _currentTokenId++;
        _safeMint(msg.sender, tokenId);
    }

    function setPrice(uint256 _priceInWei) external onlyOwner {
        mintPrice = _priceInWei;
    }

    function setImageURI(string memory _value) public onlyOwner {
        imageURI = _value;
    }

    function withdraw(address payable to, uint256 amountInWei) external onlyOwner {
        Address.sendValue(to, amountInWei);
    }

    receive() external payable {}
}