//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*

___________.____    ________    _______          ___ ___  ____ ___  _____________  __.  _________
\_   _____/|    |   \_____  \   \      \        /   |   \|    |   \/   _____/    |/ _| /   _____/
 |    __)_ |    |    /   |   \  /   |   \      /    ~    \    |   /\_____  \|      <   \_____  \ 
 |        \|    |___/    |    \/    |    \     \    Y    /    |  / /        \    |  \  /        \
/_______  /|_______ \_______  /\____|__  /      \___|_  /|______/ /_______  /____|__ \/_______  /
        \/         \/       \/         \/             \/                  \/        \/        \/ 

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract ElonHusks is ERC721A, Ownable {
    using SafeMath for uint256;

    uint public constant MAX_SUPPLY = 10000;
    uint public PRICE = 0.00 ether;
    uint public greedyAmount = 20;
    uint public greedyPrice = 0.02 ether;
    uint256 public mintLimit = 2;
    string private BASE_URI;
    bool public saleActive;
    uint256 public maxPerWallet = 150;
    
    constructor(string memory initBaseURI) ERC721A("Elon Husks", "ELON") {
        saleActive = false;
        updateBaseUri(initBaseURI);
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function getSaleActive() public view returns (bool) {
        return saleActive == true;
    }

    function updateBaseUri(string memory baseUri) public onlyOwner {
        BASE_URI = baseUri;
    }

    function updatePrice(uint price) public onlyOwner {
        PRICE = price;
    }

    function updateGreedyPrice(uint newGreedyPrice) public onlyOwner {
        greedyPrice = newGreedyPrice;
    }

    function updateGreedyAmount(uint256 newGreedyAmount) public onlyOwner {
        greedyAmount = newGreedyAmount;
    }

    function updateMaxPerWallet(uint256 newMaxPerWallet) public onlyOwner {
        maxPerWallet = newMaxPerWallet;
    }

    function updateMintLimit(uint256 newMintLimit) public onlyOwner {
        mintLimit = newMintLimit;
    }

    function ownerMint(address to, uint256 quantity) public onlyOwner {
        _safeMint(to, quantity);
    }

    function mint(uint256 quantity) external payable {
        require(saleActive, 
        "Sale is not active"
        );
        require(
            quantity <= mintLimit,
            "Too many tokens for one transaction"
        );
        require(
            PRICE * quantity <= msg.value, 
            "Insufficient funds sent"
        );
        require(
            balanceOf(msg.sender) + quantity <= maxPerWallet,
            "Too many tokens for one wallet"
        );
        secureMint(quantity);
    }

    function greedyMint() external payable {
        require(
            saleActive, 
            "Sale is not active"
        );
        require(
            greedyPrice <= msg.value, 
            "Insufficient funds sent"
        );
        require(
            balanceOf(msg.sender) + greedyAmount <= maxPerWallet,
            "Too many tokens for one wallet"
        );
        require(
            totalSupply().add(greedyAmount) < MAX_SUPPLY, 
            "No items left to mint"
        );
        _safeMint(msg.sender, greedyAmount);
    }

    function secureMint(uint256 quantity) internal {
        require(
            quantity > 0, 
            "Quantity cannot be zero"
        );
        require(
            totalSupply().add(quantity) < MAX_SUPPLY, 
            "No items left to mint"
        );
        _safeMint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
}