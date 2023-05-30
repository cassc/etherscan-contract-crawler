// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DBcaptainZ is Ownable, ERC721A, ReentrancyGuard {
    string public baseTokenURI;
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable maxSupply;

    struct SaleConfig {
        uint32 mintStartTime;
        uint64 mintPrice;
    }

    SaleConfig public saleConfig;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) ERC721A("DBcaptainZ", "DBCZ", maxBatchSize_, collectionSize_) {
        maxPerAddressDuringMint = maxBatchSize_;
        maxSupply = collectionSize_;
    }

    function born(uint256 quantity) external payable {
        SaleConfig memory config = saleConfig;

        uint256 mintPrice = uint256(config.mintPrice);
        uint256 mintStartTime = uint256(config.mintStartTime);

        require(isbornOn(mintStartTime), "born has not begun yet");
        require(totalSupply() + quantity <= maxSupply, "reached max supply");
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not born this many"
        );
        _safeMint(msg.sender, quantity);
        if (mintPrice > 0) {
            refundIfOver(mintPrice * quantity);
        }
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isbornOn(uint256 mintStartTime) public view returns (bool) {
        return block.timestamp >= mintStartTime;
    }

    function setupBornInfo(
        uint64 mintPriceWei,
        uint32 mintStartTime
    ) external onlyOwner {
        saleConfig = SaleConfig(mintStartTime, mintPriceWei);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(
        uint256 quantity
    ) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(
        uint256 tokenId
    ) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
}