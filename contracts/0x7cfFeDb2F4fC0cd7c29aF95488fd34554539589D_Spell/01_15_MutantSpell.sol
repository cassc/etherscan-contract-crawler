// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721AS.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Spell is Ownable, ERC721AS, ReentrancyGuard {
    constructor(
    ) ERC721AS("SPELL", "Mutant Spell", 10, 5555) {}

    function reserveMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "Can't mint more."
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
        if (quantity % maxBatchSize != 0){
            _safeMint(msg.sender, quantity % maxBatchSize);
        }
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Spell does not exist.");
        string memory bookType = toString(bookTypeOf(tokenId));
        string memory spellType = toString(spellTypeOf(tokenId));
        string memory spellLevel = toString(spellLevelOf(tokenId));
        string memory tokenIdText = toString(tokenId);
        string memory baseURI = _baseURI();
        string memory output = string(abi.encodePacked(baseURI, bookType, '-', spellType, '-', spellLevel, '-', tokenIdText));
        return output;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    bool public publicSaleStatus = false; //TEST PROD false
    uint256 public publicPrice = 0.006900 ether; //TEST PROD 0.0069
    uint256 public amountForPublicSale = 5555;
    uint256 public immutable publicSalePerMint = 10;

    function publicSaleMint(uint256 quantity) external payable {
        require(publicSaleStatus,"Public sale has not started.");
        require(totalSupply() + quantity <= collectionSize,"Max supply reached.");
        require(amountForPublicSale >= quantity,"Public sale limit reached.");
        require(quantity <= publicSalePerMint,"Single transaction limit reached.");
        uint maxFreeNum = potionBalanceOf();
        if (maxFreeNum == 0) {
            maxFreeNum = 1;
        } else if (maxFreeNum > 5) {
            maxFreeNum = 5;
        }
        if (numberMinted(msg.sender) + quantity > maxFreeNum) {
            uint numberToPay;
            if ( numberMinted(msg.sender) >= maxFreeNum) {
                numberToPay = quantity;
            } else {
                numberToPay = numberMinted(msg.sender) + quantity - maxFreeNum;
            }
            require(uint256(publicPrice) * numberToPay <= msg.value, string(abi.encodePacked("Not enough ETH, you are allowed ", toString(maxFreeNum), " free mint")));
        }
        _safeMint(msg.sender, quantity);
        amountForPublicSale -= quantity;
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSaleStatus = status;
    }

    function getPublicSaleStatus() external view returns(bool) {
        return publicSaleStatus;
    }


    function setPotionAddress(address addr) external onlyOwner {
        potionAddress = addr;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}