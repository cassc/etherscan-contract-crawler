// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// TODO: Add dev mint with list of wallets
contract Derpz is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    uint64 public price = 0.005 ether;
    uint16 public supply = 8888;
    uint8 public maxMintPerTx = 8;
    bool public open;
    bool public revealed;
    string baseURI;

    constructor(string memory baseURI_) ERC721A("Derpz", "DERPZ") {
        baseURI = baseURI_;
    }

    function mint(uint256 quantity) external payable nonReentrant {
        require(open, "mint: not open");
        require(quantity <= maxMintPerTx, "mint: limit reached");
        require(quantity > 0, "mint: must mint something");
        require(
            _totalMinted() + quantity <= supply,
            "mint: max supply reached"
        );
        require(msg.value >= quantity * price, "mint: insufficient funds");

        _mint(msg.sender, quantity);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
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

    function withdraw(address payable to) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, bytes memory data) = to.call{value: balance}("");
        require(sent, "withdraw: failed to send Ether");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "tokenURI: token not found");
        if (!revealed) {
            return baseURI;
        }
        return string.concat(baseURI, _toString(tokenId), ".json");
    }

    function devMint(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyOwner {
        require(
            recipients.length == quantities.length,
            "devMint: array lengths must match"
        );
        for (uint256 i = 0; i < recipients.length; ++i) {
            require(
                recipients[i] != address(0),
                "devMint: address can't be zero address"
            );
            _mint(
                recipients[i],
                quantities[i]
            );
        }
        require(totalSupply() <= supply, "devMint: supply exceeded");
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMint(bool open_) external onlyOwner {
        open = open_;
    }

    function setRevealed(bool revealed_) external onlyOwner {
        revealed = revealed_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}