// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Created By: Lorenzo
contract SpookyBoysCountryClub is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    mapping(address => bool) private whitelist;

    string private baseURI;
    bool private saleActive = false;
    bool private allowWhitelistRedemption = false;
    uint256 private whitelistMaxMint = 5;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _numAirdroped;
    Counters.Counter private _numMinted;

    // Total Spooky Boys: 13,000
    uint256 public constant MAX_PUBLIC_MINT = 12985;
    uint256 public constant AIRDROP_RESERVE = 15;

    uint256 public constant MAX_SPOOKY_BOY_PURCHASE = 5;
    uint256 public constant PRICE_PER_SPOOKY_BOY = 60000000000000000; // 0.06 ETH
    

    constructor(
        string memory name,
        string memory symbol,
        string memory uri) ERC721(name, symbol) {
        baseURI = uri;
    }

    function startSale() external onlyOwner {
        require(!saleActive, "The sale is active already");
        saleActive = true;
    }

    function pauseSale() external onlyOwner {
        require(saleActive, "The sale is not active, so it cannot be paused");
        saleActive = false;
    }

    function allowEarlyRedemption() external onlyOwner {
        require(!allowWhitelistRedemption, "The whitelist redemption is active already");
        allowWhitelistRedemption = true;
    }

    function pauseEarlyRedemption() external onlyOwner {
        require(allowWhitelistRedemption, "The whitelist redemption is not active, so it cannot be paused");
        allowWhitelistRedemption = false;
    }

    function setWhitelistMaxMint(uint256 amount) external onlyOwner {
        whitelistMaxMint = amount;
    }

    function whitelistPreSaleAddresses(address[] calldata to) external onlyOwner {
        for(uint i = 0; i < to.length; i++){
            whitelist[to[i]] = true;
        }
    }

    function mintSpookyBoys(uint256 numberOfSpookyBoys) external payable nonReentrant {
        require(
            saleActive ||
            (whitelist[msg.sender] && numberOfSpookyBoys <= whitelistMaxMint && allowWhitelistRedemption), 
            "You may not mint a spooky boy yet. Stay tuned!");
        require(numberOfSpookyBoys > 0, "You cannot mint 0  Spooky Boys.");
        require(SafeMath.add(_numMinted.current(), numberOfSpookyBoys) <= MAX_PUBLIC_MINT, "Exceeds maximum supply.");
        require(numberOfSpookyBoys <= MAX_SPOOKY_BOY_PURCHASE, "Exceeds maximum Spooky Boys in one transaction.");
        require(getNFTPrice(numberOfSpookyBoys) <= msg.value, "Amount of Ether sent is not correct.");
        
        whitelist[msg.sender] = false;

        for(uint i = 0; i < numberOfSpookyBoys; i++){
            uint256 tokenIndex = _tokenIdCounter.current();
            _numMinted.increment();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenIndex);   
        }
    }

    function airdropSpookyBoys(address[] calldata to, uint256[] calldata numberOfSpookyBoys) 
        external 
        onlyOwner
    {
        require(to.length == numberOfSpookyBoys.length, "The arrays must be the same length.");
        
        uint256 sum = 0;
        for(uint i = 0; i < numberOfSpookyBoys.length; i++){
            sum = sum + numberOfSpookyBoys[i];
        }
        
        require(SafeMath.add(_numAirdroped.current(), sum) <= AIRDROP_RESERVE, "Exceeds maximum airdrop reserve.");
        
        for(uint i = 0; i < to.length; i++){
            for(uint j = 0; j < numberOfSpookyBoys[i]; j++){
                uint256 tokenId = _tokenIdCounter.current(); 
                _tokenIdCounter.increment();
                _numAirdroped.increment();
                _safeMint(to[i], tokenId);
            }
            
        }  
    }

    function getNFTPrice(uint256 amount) public pure returns (uint256) {
        return SafeMath.mul(amount, PRICE_PER_SPOOKY_BOY);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}