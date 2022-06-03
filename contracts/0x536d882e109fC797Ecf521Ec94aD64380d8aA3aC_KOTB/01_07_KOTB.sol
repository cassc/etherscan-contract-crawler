// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract KOTB is Ownable, ERC721A {

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant MAX_SALE_MINTS = 7677;
    uint256 public constant MAX_FOUNDERS_SUPPLY = 100;
    uint256 public publicPrice = 0.0 ether;
    uint256 public maxMint = 5;
    uint256 public amountMintedFounders;
    uint256 public amountMintedSale;
    bool public publicSaleActive = false;
    string public _tokenBaseURI;

    constructor() ERC721A ("Kids On The Block","KOTB") {}

    function mint(uint256 quantity) external payable {
        require(totalSupply() < MAX_SUPPLY, "We are sold out!");
        require(amountMintedSale < MAX_SALE_MINTS, "We are sold out!");
        require(publicSaleActive, "Public Sale is Paused");
        require(quantity > 0, "Min mint is 1 Kid");
        require(quantity <= maxMint, "Transaction exceeds max mint.");
        require( totalSupply() + quantity <= MAX_SUPPLY, "Transaction exceeds max supply.");
        require( publicPrice * quantity == msg.value, "Ether amount is incorrect.");
        amountMintedSale += quantity;
        _safeMint(msg.sender, quantity);
    }

    
    function giftMint(uint256 quantity, address receiver) external onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "We are sold out!");
        require(amountMintedFounders + quantity <= MAX_FOUNDERS_SUPPLY, "Founder Supply has been claimed already.");
        require(quantity > 0, "Min mint is 1 Kid.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Transaction exceeds max supply.");
        amountMintedFounders += quantity;
        _safeMint(receiver, quantity);
    }

    function setPublicPrice(uint256 _mintPrice) external onlyOwner {
        publicPrice = _mintPrice;
    }
    
    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }
    

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return _tokenBaseURI;
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance can't be zero");
        _withdraw(owner(), address(this).balance);
    }
}