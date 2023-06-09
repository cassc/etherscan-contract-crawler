// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract ArbitrumApes is ERC721A, Ownable, DefaultOperatorFilterer {
    bool public isPublicSale = false;
    uint256 public max_supply = 7777;
    uint256 public price = 0.003 ether;
    uint256 public per_wallet = 11;
    uint256 public free_per_wallet = 1;
    string private baseUri = "null";

    constructor(string memory _baseUri) ERC721A("ArbitrumApes", "AAP") {
        baseUri = _baseUri;
    }

    function mint(uint256 quantity) external payable {
        require(isPublicSale, "Sale not active");
        require(msg.sender == tx.origin, "No contracts allowed");
        require(balanceOf(msg.sender) + quantity <= per_wallet, "Exceeds max per wallet");
        require(totalSupply() + quantity <= max_supply, "Exceeds max supply");
        if (balanceOf(msg.sender) == 0) {
                require(price * (quantity - free_per_wallet) <= msg.value, "Insufficient funds sent");
        } else {
                require(price * quantity <= msg.value, "Insufficient funds sent");
        }
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function ownerMint(uint256 quantity, address to) external onlyOwner {
        require(totalSupply() + quantity <= max_supply,"Exceeds max supply");
        _mint(to, quantity);
    }

    function flipPublicSale() external onlyOwner {
        isPublicSale = !isPublicSale;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPerWallet(uint256 _per_wallet) external onlyOwner {
        per_wallet = _per_wallet;
    }

    function setFreePerWallet(uint256 _free_per_wallet) external onlyOwner {
        free_per_wallet = _free_per_wallet;
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}