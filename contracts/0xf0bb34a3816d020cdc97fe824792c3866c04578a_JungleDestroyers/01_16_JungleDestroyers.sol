// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
 
// Created By: LoMel
contract JungleDestroyers is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _numAirdroped;
    Counters.Counter private _numMinted;
    
    enum ContractState { PAUSED, PRESALE, PUBLIC }
    ContractState public currentState = ContractState.PAUSED;

    uint256 public constant MAX_PUBLIC_MINT = 8858;
    uint256 public constant AIRDROP_RESERVE = 30;
    address public constant ARTIST_ADDRESS = 0x33379b2c46806B741F7a5a6fb7783d87f37AFaBc;
    
    uint256 public pricePerJungleDestroyer = .04 ether;

    string private baseURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri) ERC721(name, symbol) {
        baseURI = uri;
    }
    
    function changeContractState(ContractState _state) external onlyOwner {
        currentState = _state;
        if(currentState == ContractState.PRESALE) {
            pricePerJungleDestroyer = .04 ether;
        }
        else if(currentState == ContractState.PUBLIC) {
            pricePerJungleDestroyer = .06 ether;
        }
    }
    
    function mintJungleDestroyer(uint256 _numberOfJungleDestroyers) external payable nonReentrant{
        require(currentState != ContractState.PAUSED, "The sale is not active.");
        require(_numberOfJungleDestroyers > 0, "You cannot mint 0 Jungle Destroyers.");
        require(getNFTPrice(_numberOfJungleDestroyers) <= msg.value, "Amount of Ether sent is not correct.");
        require(SafeMath.add(_numMinted.current(), _numberOfJungleDestroyers) <= MAX_PUBLIC_MINT, "Exceeds maximum supply.");

        for(uint i = 0; i < _numberOfJungleDestroyers; i++){
            uint256 tokenIndex = _tokenIdCounter.current();
            _numMinted.increment();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenIndex);   
        }
    }

    function airdropJungleDestroyer(uint256 _numberOfJungleDestroyers) external onlyOwner {
        require(_numberOfJungleDestroyers > 0, "You cannot mint 0 Jungle Destroyers.");
        require(SafeMath.add(_numAirdroped.current(), _numberOfJungleDestroyers) <= AIRDROP_RESERVE, "Exceeds maximum airdrop reserve.");

        for(uint i = 0; i < _numberOfJungleDestroyers; i++){
            uint256 tokenId = _tokenIdCounter.current(); 
            _tokenIdCounter.increment();
            _numAirdroped.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

     function getNFTPrice(uint256 _amount) public view returns (uint256) {
        return SafeMath.mul(_amount, pricePerJungleDestroyer);
    }

    function payout() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(ARTIST_ADDRESS), balance/20);
        Address.sendValue(payable(msg.sender), (balance*19)/20);
    }


    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}