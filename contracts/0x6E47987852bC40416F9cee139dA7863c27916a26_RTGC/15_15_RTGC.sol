// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RTGC is Ownable, ERC721A, ReentrancyGuard {
    uint256 public publicSalePrice = 0 ether;
    bool public publicSaleState = false;

    uint256 public totalCount = 3600;

    constructor() ERC721A("Roaring Tiger Golf Club", "RTGC", 1000, 3600) {}

    event ChangedPublicSale(bool newStatus);
    event ChangedPublicMintPrice(uint256 newPrice);

    function changePublicSale(bool _publicSale) public onlyOwner {
        publicSaleState = _publicSale;
        emit ChangedPublicSale(_publicSale);
    }

    function changePublicSalePrice(
        uint256 newPublicSalePrice
    ) external onlyOwner {
        publicSalePrice = newPublicSalePrice;
        emit ChangedPublicMintPrice(newPublicSalePrice);
    }

    function reserveRTGC(uint256 _amount) external onlyOwner {
        require(
            totalSupply() + _amount <= totalCount,
            "RTGC: Mint Will exceed CollectionSize"
        );
        _safeMint(msg.sender, _amount);
    }

    function publicMint(uint256 quantity) external payable nonReentrant {
        require(
            totalSupply() + quantity <= totalCount,
            "RTGC: Mint Will exceed CollectionSize"
        );

        uint256 totalCost = publicSalePrice * quantity;

        require(msg.value >= totalCost, "Wrong Amount Sent");
        require(publicSaleState, "Sale Not Started");

        _safeMint(msg.sender, quantity);
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}