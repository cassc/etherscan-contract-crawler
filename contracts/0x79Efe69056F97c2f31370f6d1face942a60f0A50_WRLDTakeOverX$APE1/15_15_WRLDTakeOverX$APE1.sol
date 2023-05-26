// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WRLDTakeOverX$APE1 is Ownable, ERC721A, ReentrancyGuard {

    bool public publicSale;

    uint256 public constant MINT_PRICE_ETH = 0.1 ether;
    uint256 public constant MAX_TOKENS = 100;
    uint256 public constant MAX_BATCH = 10;

    address public constant PAYMENT_ADDRESS = 0xb92376FE898D899E636748D1e9A5f3fc779eFEF0;
    string private _baseTokenURI;

    constructor() ERC721A("WRLDTakeOverX$APE1", "WTOG", MAX_BATCH, MAX_TOKENS) {

    }

    function publicSaleMint(uint256 quantity) external payable nonReentrant {
        require(msg.sender == tx.origin);
        require(publicSale, "Not public");
        require(totalSupply() + quantity <= MAX_TOKENS, "Over max");
        require(MINT_PRICE_ETH * quantity == msg.value, "Bad ether val");
        _safeMint(msg.sender, quantity);
    }

    function setPublicSale(bool isPublic) external onlyOwner {
        publicSale = isPublic;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        payable(PAYMENT_ADDRESS).transfer(address(this).balance);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
}