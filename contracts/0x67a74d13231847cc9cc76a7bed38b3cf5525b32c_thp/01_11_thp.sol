// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/529cceeda9f5f8e28812c20042cc57626f784718/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";

contract thp is ERC721A, Ownable, DefaultOperatorFilterer {
    uint256 public constant maxSupply = 10000;
    uint256 public constant maxPerWallet = 15;
    uint256 public constant maxPerTx = 5;
    uint256 public price = 0.00069 ether;
    string public baseURI = "";
    bool public saleLive = false;

    mapping(address => uint256) public walletMinted;

    constructor() ERC721A("Treehouse Punks", "THP") {}

    function publicMint(uint256 _amountToMint) payable external {
        address _caller = msg.sender;
        require(_amountToMint > 0);
        require(saleLive, "Public sale not live");
        require(maxSupply >= totalSupply() + _amountToMint, "Exceeds max supply");
        require(maxPerTx >= _amountToMint, "Exceeds max per tx");
        require(maxPerWallet >= walletMinted[_caller] + _amountToMint, "Exceeds max per wallet");
        require(msg.value == price * _amountToMint, "Wrong ether amount sent");
        require(tx.origin == _caller, "No contracts");

        walletMinted[_caller] += _amountToMint;
        _mint(_caller, _amountToMint);
    }

    function ownerMint(uint256 _amount, address _to) external onlyOwner {
        require(maxSupply >= totalSupply() + _amount, "Exceeds max supply");
        _mint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send");
    }

    function setSale(bool _state) external onlyOwner {
        saleLive = _state;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId)
            )
        ) : "";
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}