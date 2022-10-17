// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";

error NotLive();
error Restricted();
error MintLimit();
error InsufficientFund();
error MaxSupply();
error WithdrawFailed();

contract FoundersGenuinelyDead is Ownable, ERC721A {
    string public baseURI;
    bool public saleStatus;
    uint256 public price;
    uint256 public maxMintAmount;
    uint256 public maxSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory uri,
        uint256 _price,
        uint256 _maxMintAmount,
        uint256 _maxSupply
    ) ERC721A(_name, _symbol) {
        baseURI = uri;
        price = _price;
        maxMintAmount = _maxMintAmount;
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setSalesStatus(bool _status) external onlyOwner {
        saleStatus = _status;
    }

    function mint(uint256 _quantity) external payable {
        if (!saleStatus) revert NotLive();
        if (msg.sender != tx.origin) revert Restricted();
        if (totalSupply() + _quantity > maxSupply) revert MaxSupply();
        if (_numberMinted(msg.sender) + _quantity > maxMintAmount) revert MintLimit();
        if (msg.value < price * _quantity) revert InsufficientFund();
        _mint(msg.sender, _quantity);
    }

    function devMint(uint256 _quantity) external onlyOwner {
        if (totalSupply() + _quantity > maxSupply) revert MaxSupply();
        _mint(msg.sender, _quantity);
    }

    function withdraw(address payable _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _receiver.call{ value: balance }("");
        if (!success) revert WithdrawFailed();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length != 0
                ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), ".json"))
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}