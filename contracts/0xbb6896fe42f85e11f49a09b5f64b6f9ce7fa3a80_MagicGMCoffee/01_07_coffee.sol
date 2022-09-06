// SPDX-License-Identifier: MIT

/**
   _____                 .__           ________    _____    _________         _____  _____              
  /     \ _____     ____ |__| ____    /  _____/   /     \   \_   ___ \  _____/ ____\/ ____\____   ____  
 /  \ /  \\__  \   / ___\|  |/ ___\  /   \  ___  /  \ /  \  /    \  \/ /  _ \   __\\   __\/ __ \_/ __ \ 
/    Y    \/ __ \_/ /_/  >  \  \___  \    \_\  \/    Y    \ \     \___(  <_> )  |   |  | \  ___/\  ___/ 
\____|__  (____  /\___  /|__|\___  >  \______  /\____|__  /  \______  /\____/|__|   |__|  \___  >\___  >
        \/     \//_____/         \/          \/         \/          \/                        \/     \/ 

 @powered by: amadeus-nft.io
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MagicGMCoffee is Ownable, ERC721A, ReentrancyGuard {
    constructor(
    ) ERC721A("MagicGMCoffee", "MGC") {}
    
    uint256 public collectionSize = 1000;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // For marketing etc.
    function reserveMintBatch(uint256[] calldata quantities, address[] calldata tos) external onlyOwner {
        for(uint256 i = 0; i < quantities.length; i++){
            require(
                totalSupply() + quantities[i] <= collectionSize,
                "Too many already minted before dev mint."
            );
            _safeMint(tos[i], quantities[i]);
        }
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        address amadeusAddress = address(0x718a7438297Ac14382F25802bb18422A4DadD31b);
        uint256 royaltyForAmadeus = address(this).balance / 100 * 5;
        uint256 remain = address(this).balance - royaltyForAmadeus;
        (bool success, ) = amadeusAddress.call{value: royaltyForAmadeus}("");
        require(success, "Transfer failed.");
        (success, ) = msg.sender.call{value: remain}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
    //public sale
    bool public publicSaleStatus = true;
    uint256 public publicPrice = 0.010000 ether;
    uint256 public amountForPublicSale = 1000;
    // per mint public sale limitation
    uint256 public immutable publicSalePerMint = 2;

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        require(publicSaleStatus, "Public Sale not Start");
        require(totalSupply() + quantity <= collectionSize, "Reached max supply");
        require(_numberMinted(msg.sender) <= 2, "Reached max amount per address");
        require(quantity <= publicSalePerMint, "reached max amount per mint");

        _safeMint(msg.sender, quantity);
        amountForPublicSale -= quantity;
        refundIfOver(uint256(publicPrice) * quantity);
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSaleStatus = status;
    }
}