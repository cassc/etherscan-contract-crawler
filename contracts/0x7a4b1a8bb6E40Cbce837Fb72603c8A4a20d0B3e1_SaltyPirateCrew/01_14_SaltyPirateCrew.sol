// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SaltyPirateCrew is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant GIFT_BUFFER = 67;
    uint256 public constant PRICE = 0.06 ether;
    uint256 public constant SNAPSHOT = 232;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter public giftsSent;
    Counters.Counter public _snapshotCounter; 
   
    address private signer;
    uint256 public maxPresaleMint;    
    string public baseURI;
    
    enum ContractState { PAUSED, PRESALE1, PRESALE2, PUBLIC }
    ContractState public currentState = ContractState.PAUSED;

    mapping(address => uint256) public whitelist; 

    constructor(
        address _signer, 
        uint256 _maxPresaleMint, 
        string memory _URI) ERC721("SaltyPirateCrew", "SPC") {
        signer = _signer;
        maxPresaleMint = _maxPresaleMint;
        baseURI = _URI;
    }

    // Verifies that the sender is whitelisted
    function _verify(address sender, bytes memory signature) internal view returns (bool) {
        return keccak256(abi.encodePacked(sender))
            .toEthSignedMessageHash()
            .recover(signature) == signer;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function giftsRemaining() public view returns (uint256) {
        return GIFT_BUFFER - giftsSent.current();
    }

    // Returns the total supply minted
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current() + _snapshotCounter.current();
    }

    // Sets a new contract state: PAUSED, PRESALE1, PRESALE2, PUBLIC.
    function setContractState(ContractState _newState) external onlyOwner {
        currentState = _newState;
    }

    // Sets a new maximum for presale minting
    function setMaxPresaleMint(uint256 _newMaxPresaleMint) external onlyOwner {
        maxPresaleMint = _newMaxPresaleMint;
    }

    function airdrop(uint256 airdropAmount, address to) public onlyOwner {
        require(airdropAmount > 0, "Airdrop != 0");
        require(_snapshotCounter.current() + airdropAmount <= SNAPSHOT, "Airdrop > Max");
        for(uint i = 0; i < airdropAmount; i++) {
            uint256 tokenId = _snapshotCounter.current();
            _snapshotCounter.increment();
            _safeMint(to, tokenId);
        } 
    }

    // Gift function that will send the address passed the gift amount
    function gift(uint256 giftAmount, address to) public onlyOwner {
        require(giftAmount > 0, "Gift != 0");
        require(giftsSent.current() + giftAmount <= GIFT_BUFFER, "Gifting exceeded");
        require(giftAmount + _tokenIdCounter.current() <= MAX_SUPPLY - SNAPSHOT , "Gift > Max");

        for(uint i = 0; i < giftAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current() + SNAPSHOT;
            _tokenIdCounter.increment();
            giftsSent.increment();
            _safeMint(to, tokenId);
        } 
    }

    // Mint function uses OpenZeppelin's mint functions to ensure safety.
    // Requires ensure that minting is 1-10 and that user is whitelisted. Does not allow to mint beyond the gift buffer or whitelisted allocation.
    function firstPresale(uint256 mintAmount, bytes memory _signature) public payable nonReentrant {
        require(currentState == ContractState.PRESALE1, "First presale not in session");
        require(_verify(msg.sender, _signature), "You are not on the whitelist");
        require(mintAmount > 0, "Can't mint 0");
        require(mintAmount + _tokenIdCounter.current() <= MAX_SUPPLY - giftsRemaining() - SNAPSHOT, "Minting more than max supply");
        require(mintAmount < 11, "Max mint is 10");
        require(msg.value == PRICE * mintAmount, "Wrong price");
        require(whitelist[msg.sender] + mintAmount <= maxPresaleMint, "Minting more than your whitelist allocation");

        for(uint i = 0; i < mintAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current() + SNAPSHOT;
            _tokenIdCounter.increment();
            whitelist[msg.sender]++;
            _safeMint(msg.sender, tokenId);
        }
    }

    // Mint function uses OpenZeppelin's mint functions to ensure safety.
    // Requires ensure that minting is 1-10 and that user is whitelisted. Does not allow to mint beyond the gift buffer.
    function secondPresale(uint256 mintAmount, bytes memory _signature) public payable nonReentrant {
        require(currentState == ContractState.PRESALE2, "Second presale not in session");
        require(_verify(msg.sender, _signature), "You are not on the whitelist");
        require(mintAmount > 0, "Can't mint 0");
        require(mintAmount + _tokenIdCounter.current() <= MAX_SUPPLY - giftsRemaining() - SNAPSHOT , "Minting more than max supply");
        require(mintAmount < 11, "Max mint is 10");
        require(msg.value == PRICE * mintAmount, "Wrong price");

        for(uint i = 0; i < mintAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current() + SNAPSHOT;
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    // Mint function uses OpenZeppelin's mint functions to ensure safety.
    // Requires ensure that minting is 1-10. Does not allow to mint beyond the gift buffer.
    function mint(uint256 mintAmount) public payable nonReentrant {
        require(currentState == ContractState.PUBLIC, "Public sale not started");
        require(mintAmount > 0, "Can't mint 0");
        require(mintAmount + _tokenIdCounter.current() <= MAX_SUPPLY - giftsRemaining() - SNAPSHOT, "Minting more than max supply");
        require(mintAmount < 11, "Max mint is 10");
        require(msg.value == PRICE * mintAmount, "Wrong price");

        for(uint i = 0; i < mintAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current() + SNAPSHOT;
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    // Withdraw funds
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}