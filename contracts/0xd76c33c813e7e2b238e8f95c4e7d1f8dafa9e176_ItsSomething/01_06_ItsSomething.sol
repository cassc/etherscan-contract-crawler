// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract ItsSomething is ERC721A, Ownable, ReentrancyGuard {

    bool public saleEnabled = false;
    string public baseURI;  
    uint256 public price = 0.001 ether;
    uint256 public maxPerTx = 1; 
    uint256 public maxPerWallet = 3;
    uint256 public maxFreeSupply = 4444;
    uint256 public maxSupply = 8888;
    uint256 public freeMintPerWallet = 3;
    mapping (address => uint256) public addressMint;

    constructor(string memory name, string memory symbol) ERC721A(name, symbol){}

    function mint(uint256 amount) external payable {
        uint cost = price;
        if(msg.value == 0 && totalSupply() + amount <= maxFreeSupply) {
            require(addressMint[msg.sender] + amount <= freeMintPerWallet,"Address has been claimed");
            cost = 0;
            addressMint[msg.sender] += amount;
        }
        require(saleEnabled, "Sale is not live");
        require(amount <= maxPerTx, "Exceeded max per txn");
        require(msg.value == amount * cost,"Incorrect price");
        require(totalSupply() + amount <= maxSupply,"Sold out");
        require(numberMinted(msg.sender) + amount <= maxPerWallet,"Exceeded max per wallet");
        _safeMint(msg.sender, amount);
    }

    function airdrop(address to ,uint256 amount) external onlyOwner {
        _safeMint(to, amount);
    }

    function ownerBatchMint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply,"Exceeded batch mint over max supply");
        _safeMint(msg.sender, amount);
    }

    function toggleSale() external onlyOwner {
        saleEnabled = !saleEnabled;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxFreeSupply(uint256 maxFreeSupply_) external onlyOwner {
        maxFreeSupply = maxFreeSupply_;
    }
    function setFreeMintPerWallet(uint256 freeMintPerWallet_) external onlyOwner {
        freeMintPerWallet = freeMintPerWallet_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        require(payable(owner()).send(address(this).balance), "Not enough funds to withdraw");
    }
}