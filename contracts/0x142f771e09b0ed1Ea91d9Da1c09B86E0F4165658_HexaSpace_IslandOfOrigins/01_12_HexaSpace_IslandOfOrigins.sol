//      ___           ___           ___           ___           ___           ___           ___           ___           ___
//     /\__\         /\  \         |\__\         /\  \         /\  \         /\  \         /\  \         /\  \         /\  \
//    /:/  /        /::\  \        |:|  |       /::\  \       /::\  \       /::\  \       /::\  \       /::\  \       /::\  \
//   /:/__/        /:/\:\  \       |:|  |      /:/\:\  \     /:/\ \  \     /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/\:\  \
//  /::\  \ ___   /::\~\:\  \      |:|__|__   /::\~\:\  \   _\:\~\ \  \   /::\~\:\  \   /::\~\:\  \   /:/  \:\  \   /::\~\:\  \
// /:/\:\  /\__\ /:/\:\ \:\__\ ____/::::\__\ /:/\:\ \:\__\ /\ \:\ \ \__\ /:/\:\ \:\__\ /:/\:\ \:\__\ /:/__/ \:\__\ /:/\:\ \:\__\
// \/__\:\/:/  / \:\~\:\ \/__/ \::::/~~/~    \/__\:\/:/  / \:\ \:\ \/__/ \/__\:\/:/  / \/__\:\/:/  / \:\  \  \/__/ \:\~\:\ \/__/
//      \::/  /   \:\ \:\__\    ~~|:|~~|          \::/  /   \:\ \:\__\        \::/  /       \::/  /   \:\  \        \:\ \:\__\
//      /:/  /     \:\ \/__/      |:|  |          /:/  /     \:\/:/  /         \/__/        /:/  /     \:\  \        \:\ \/__/
//     /:/  /       \:\__\        |:|  |         /:/  /       \::/  /                      /:/  /       \:\__\        \:\__\
//     \/__/         \/__/         \|__|         \/__/         \/__/                       \/__/         \/__/         \/__/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract HexaSpace_IslandOfOrigins is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private landQty;
    string private baseURI;

    bool public paused = false;
    uint256 public totalSupply = 24372;
    uint256 public presaleCost = 0.2 ether;
    uint256 public cost = 0.4 ether;
    mapping(uint256 => bool) public isMintedLand;

    constructor(string memory baseURI_) ERC721("HexaSpace Island Of Origins", "HEXAIO") {
        baseURI = baseURI_;
    }

    function mint(uint256 _tokenId) public payable {
        require(_tokenId >= 2175 && _tokenId < totalSupply, "Cant mint this land");
        require(!paused, "The contract is paused");
        require(!isMintedLand[_tokenId], "Land already minted");
        require(landQty.current() <= totalSupply, "Mint exceeds supply");
        if (landQty.current() < 2000) {
            require(msg.value >= presaleCost, "Insufficient funds");
        } else {
            require(msg.value >= cost, "Insufficient funds");
        }
        landQty.increment();
        isMintedLand[_tokenId] = true;
        _safeMint(msg.sender, _tokenId);
    }

    function mintReserved(uint256 _tokenId) public onlyOwner {
        require(_tokenId >= 0 && _tokenId <= totalSupply, "Cant mint this land");
        require(!isMintedLand[_tokenId], "Land already minted");
        require(landQty.current() <= totalSupply, "Mint exceeds supply");
        landQty.increment();
        isMintedLand[_tokenId] = true;
        _safeMint(msg.sender, _tokenId);
    }

    function getSupply() public view returns (uint256) {
        return landQty.current();
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}