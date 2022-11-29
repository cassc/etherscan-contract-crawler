// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {DefaultOperatorFilterer} from "./Opensea/DefaultOperatorFilterer.sol";

// ░░░██╗░██╗░██╗░░░░░███████╗░█████╗░██████╗░███╗░░██╗░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░
// ██████████╗██║░░░░░██╔════╝██╔══██╗██╔══██╗████╗░██║██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗
// ╚═██╔═██╔═╝██║░░░░░█████╗░░███████║██████╔╝██╔██╗██║██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║
// ██████████╗██║░░░░░██╔══╝░░██╔══██║██╔══██╗██║╚████║██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║
// ╚██╔═██╔══╝███████╗███████╗██║░░██║██║░░██║██║░╚███║╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝
// ░╚═╝░╚═╝░░░╚══════╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░
// by American Crypto Academy

// Powered by: https://nalikes.com

contract LearnCrypto is ERC1155Supply, DefaultOperatorFilterer, Ownable {

    string public uriPrefix = "";

    uint256 public maxSupply = 10000;
    uint256 public remainingTeamMints = 350;

    uint256 public price = 0.1 ether;

    uint256 public maxMintAmountPerTx = 5;

    bool public paused = false;

    constructor(
        uint256 _price
    ) ERC1155("") {
        setPrice(_price);
    }

    // MODIFIERS

    modifier notPaused() {
        require(!paused, "The contract is paused!");
        _;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(totalSupply(1) + _mintAmount <= maxSupply - remainingTeamMints, "Max supply exceeded!");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= price * _mintAmount, "Insufficient funds!");
        _;
    }

    // MINT Functions

    function mint(address to, uint256 amount) public payable notPaused mintCompliance(amount) mintPriceCompliance(amount) {
        _mint(to, 1, amount, "");
    }

    function mintAdmin(address to, uint256 amount) public onlyOwner mintCompliance(amount) {
        _mint(to, 1, amount, "");
    }

    function mintTeam(address to, uint256 amount) public onlyOwner {
        require(totalSupply(1) + amount <= maxSupply, "TEAM MINT: Max Supply Exceeded.");
        require(amount > 0 && amount <= maxMintAmountPerTx, "TEAM MINT: Invalid Amount.");
        require(amount <= remainingTeamMints, "TEAM MINT: Exceeds reserved NFTs supply.");

        remainingTeamMints -= amount;
        _mint(to, 1, amount, "");
    }

    // VIEW Functions
    
    function uri(uint256 _tokenid) override public view returns (string memory) {
        return string(
            abi.encodePacked(uriPrefix, Strings.toString(_tokenid), ".json")
        );
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // CRUD Functions

    function setMaxMintAmountPerTx(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmount;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(_newMaxSupply >= totalSupply(1) + remainingTeamMints && _newMaxSupply <= maxSupply, "Invalid Max Supply.");
        maxSupply = _newMaxSupply;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    // WITHDRAW

    function withdraw() public onlyOwner {
        
        uint256 balance = address(this).balance;

        bool success;
        (success, ) = payable(0x2767a91BCD7A780f5B00BC775208f322955Cb7A1).call{value: ((balance * 100) / 100)}("");
        require(success, "Transaction Unsuccessful");
    }
}