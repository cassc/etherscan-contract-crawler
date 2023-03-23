// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract VasarelyNFT is ERC721A, Ownable, DefaultOperatorFilterer {
    uint256 public price = 0.0064 ether;
    uint256 public supply = 1800;
    uint256 public per = 3;
    bool public isMint = false;
    string private baseUri = "ipfs://URI";

    constructor(string memory _baseUri) ERC721A("VasarelyNFT", "VASN") {
        baseUri = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function activateSale() external onlyOwner {
        isMint = !isMint;
    }

    function ownerMint(uint256 amount, address to) external onlyOwner {
        require(totalSupply() + amount < supply, "Sold out");
        _mint(to, amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function publicMint(uint256 amount) external payable {
        require(isMint, "Mint not active");
        require(balanceOf(msg.sender) + amount <= per, "Max per wallet");
        require(totalSupply() + amount <= supply, "Sold out");
        require(price * amount <= msg.value, "Insufficient funds");
        _safeMint(msg.sender, amount);
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPerWallet(uint256 _per) external onlyOwner {
        per = _per;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
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