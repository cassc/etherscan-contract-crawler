// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TheVerified is ERC721A, ReentrancyGuard, PullPayment, Ownable {
    constructor() ERC721A("TheVerified", "TheVerified") {}

    uint256 private MAX_SUPPLY = 5000;
    uint256 private PRICE = 0 ether;
    uint256 private MAX_SALE_MINT = 3;

    string private baseURI;

    function mint(uint256 mintAmount) external payable nonReentrant {
        require(mintAmount > 0, "Minted amount should be positive");
        require(
            mintAmount <= MAX_SALE_MINT,
            "Minted amount exceeds sale limit"
        );

        uint256 totalMinted = _totalMinted();

        require(
            totalMinted + mintAmount <= MAX_SUPPLY,
            "The requested amount exceeds the remaining supply"
        );

        _safeMint(msg.sender, mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = baseURI;
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return "";
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, Strings.toString(tokenId)));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}