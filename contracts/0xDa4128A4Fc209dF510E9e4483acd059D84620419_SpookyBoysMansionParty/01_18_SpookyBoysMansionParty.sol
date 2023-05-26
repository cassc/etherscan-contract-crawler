// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// mint 19
// spookeys 21
// 21 - 24 claiming
// 24th reveal

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SK.sol";
import "./SBCC.sol";

//  .-')     _ (`-.                           .-. .-')                     .-. .-')                              .-')    
// ( OO ).  ( (OO  )                          \  ( OO )                    \  ( OO )                            ( OO ).  
// (_)---\_)_.`     \ .-'),-----.  .-'),-----. ,--. ,--.   ,--.   ,--.       ;-----.\  .-'),-----.   ,--.   ,--.(_)---\_) 
// /    _ |(__...--''( OO'  .-.  '( OO'  .-.  '|  .'   /    \  `.'  /        | .-.  | ( OO'  .-.  '   \  `.'  / /    _ |  
// \  :` `. |  /  | |/   |  | |  |/   |  | |  ||      /,  .-')     /         | '-' /_)/   |  | |  | .-')     /  \  :` `.  
//  '..`''.)|  |_.' |\_) |  |\|  |\_) |  |\|  ||     ' _)(OO  \   /          | .-. `. \_) |  |\|  |(OO  \   /    '..`''.) 
// .-._)   \|  .___.'  \ |  | |  |  \ |  | |  ||  .   \   |   /  /\_         | |  \  |  \ |  | |  | |   /  /\_  .-._)   \ 
// \       /|  |        `'  '-'  '   `'  '-'  '|  |\   \  `-./  /.__)        | '--'  /   `'  '-'  ' `-./  /.__) \       / 
//  `-----' `--'          `-----'      `-----' `--' '--'    `--'             `------'      `-----'    `--'       `-----'  

// Created By: Lorenzo
contract SpookyBoysMansionParty is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    SK private immutable sk;
    SBCC private immutable sbcc;

    uint256 public constant BRONZE_KEY_ID = 1;
    uint256 public constant SILVER_KEY_ID = 69;
    uint256 public constant GOLD_KEY_ID = 420;
    uint256 public constant BRONZE_KEY_REQ_AMOUNT = 2;
    uint256 public constant RARE_KEY_REQ_AMOUNT = 1;

    uint256 public constant PUBLIC_MINT_OFFSET = 13000;
    uint256 public constant MAX_PUBLIC_MINT = 4444;

    uint256 public constant MAX_PER_PURCHASE = 10;
    uint256 public constant PRICE_PER_MANSION_SPOOKY = 130000000000000000; // 0.13 ETH

    string private baseURI;
    bool public mansionOpen = false;
    bool public publicSaleActive = false;


    Counters.Counter private _tokenIdCounter;

    event KeyUsed(uint256 keyId, uint256 spookyBoyId);
    event SpookyMinted(uint256 mansionSpookyId);
    
    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        address spooKeyContract,
        address sbccContract) ERC721(name, symbol) {
        baseURI = uri;
        sk = SK(spooKeyContract);
        sbcc = SBCC(sbccContract);
    }

    function startPublicSale() external onlyOwner {
        require(!publicSaleActive, "The public sale is already active.");
        publicSaleActive = true;
    }

    function pausePublicSale() external onlyOwner {
        require(publicSaleActive, "The public sale is already paused.");
        publicSaleActive = false;
    }
    
    function openMansion() external onlyOwner {
        require(!mansionOpen, "The time machine is already ON.");
        mansionOpen = true;
    }

    function closeMansion() external onlyOwner {
        require(mansionOpen, "The time machine is already OFF.");
        mansionOpen = false;
    }

    function mintMansionSpooky(uint256 numberOfMansionSpookyBoys) external payable nonReentrant{
        require(publicSaleActive, "You cannot buy a Mansion Spooky Boy yet. Hold tight.");
        require(numberOfMansionSpookyBoys > 0, "You cannot mint 0 Mansion Spookies.");
        require(SafeMath.add(_tokenIdCounter.current(), numberOfMansionSpookyBoys) <= MAX_PUBLIC_MINT, "Exceeds maximum supply.");
        require(numberOfMansionSpookyBoys <= MAX_PER_PURCHASE, "Exceeds maximum Spooky Boys in one transaction.");
        require(getNFTPrice(numberOfMansionSpookyBoys) <= msg.value, "Amount of Ether sent is not correct.");
        

        for(uint i = 0; i < numberOfMansionSpookyBoys; i++){
            uint256 tokenIndex = _tokenIdCounter.current() + PUBLIC_MINT_OFFSET;
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenIndex);
            emit SpookyMinted(tokenIndex);
        }
    }

    function enterMansionParty(uint256 keyId, uint256 spookyBoyId) external nonReentrant {
        require(mansionOpen, "The mansion is not open yet. We will notify you when you can enter.");
        require(sbcc.ownerOf(spookyBoyId) == msg.sender, "You don't own this Spooky Boy.");
        require(!_exists(spookyBoyId), "This Spooky Boy has already entered the mansion party.");
        uint256 requiredAmount = keyId == BRONZE_KEY_ID ? BRONZE_KEY_REQ_AMOUNT : RARE_KEY_REQ_AMOUNT;
        require(
            sk.balanceOf(msg.sender, keyId) >= requiredAmount,
            "You do not own enough of the key you are trying to use.");
        
        sk.burnKey(msg.sender, keyId, requiredAmount);
        _safeMint(msg.sender, spookyBoyId);
        emit KeyUsed(keyId, spookyBoyId);
    }

    function getNFTPrice(uint256 amount) public pure returns (uint256) {
        return SafeMath.mul(amount, PRICE_PER_MANSION_SPOOKY);
    }

    function airdropMansionSpooky(uint256 numberOfMansionSpookyBoys) external onlyOwner{
        require(numberOfMansionSpookyBoys > 0, "You cannot mint 0 Mansion Spookies.");
        require(numberOfMansionSpookyBoys <= 15, "You can only airdrop 15 Mansion Spookies.");

        require(SafeMath.add(_tokenIdCounter.current(), numberOfMansionSpookyBoys) <= MAX_PUBLIC_MINT, "Exceeds maximum supply.");        

        for(uint i = 0; i < numberOfMansionSpookyBoys; i++){
            uint256 tokenIndex = _tokenIdCounter.current() + PUBLIC_MINT_OFFSET;
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenIndex);
            emit SpookyMinted(tokenIndex);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}