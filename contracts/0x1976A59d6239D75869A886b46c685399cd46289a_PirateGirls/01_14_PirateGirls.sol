// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/ERC721A.sol";

error MintSaleNotStarted();
error MintInsufficientPayment();
error MintExceedsMaxSupply();
error MintExceedsMintLimit();

contract PirateGirls is Ownable, ERC721AQueryable, ReentrancyGuard {
    uint256 public collectionSize;
    uint256 public maxPerMint;
    uint256 public price;

    bool public saleActive = false;

    string private baseTokenURI;

    constructor(
        uint256 _collectionSize,
        uint256 _maxPerMint,
        uint256 _price
    ) ERC721A("PirateGirls", "PGIRL") {
        collectionSize = _collectionSize;
        maxPerMint = _maxPerMint;
        price = _price;
    }

    function mint(uint256 amount) external payable nonReentrant {
        if (!saleActive) revert MintSaleNotStarted();
        if (msg.value < price * amount) revert MintInsufficientPayment();
        if (amount > maxPerMint) revert MintExceedsMintLimit();
        if (totalSupply() + amount > collectionSize)
            revert MintExceedsMaxSupply();

        _safeMint(_msgSender(), amount);
    }

    // OWNER ONLY

    function devMint(uint256 amount) external onlyOwner {
        require(
            amount % maxPerMint == 0,
            "can only mint a multiple of the maxPerMint"
        );
        uint256 numChunks = amount / maxPerMint;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(_msgSender(), maxPerMint);
        }
    }

    function setCollectionSize(uint256 _collectionSize) external onlyOwner {
        collectionSize = _collectionSize;
    }

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setSaleActive(bool _active) external onlyOwner {
        saleActive = _active;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool ok, ) = payable(_msgSender()).call{value: balance}("");
        require(ok, "Failed to withdraw payment");
    }

    // INTERNAL

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}