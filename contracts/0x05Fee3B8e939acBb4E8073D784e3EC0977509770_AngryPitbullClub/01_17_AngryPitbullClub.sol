// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Created By: LoMel
contract AngryPitbullClub is ERC721Enumerable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _numAirdroped;
    Counters.Counter private _numMinted;
    
    enum ContractState { PAUSED, PRESALE, PUBLIC }
    ContractState public currentState = ContractState.PAUSED;

    // Total supply 10,000
    uint256 public constant MAX_PUBLIC_MINT = 9950;
    uint256 public constant AIRDROP_RESERVE = 50;
    
    mapping(address => uint256) public addressMinted; 

    uint256 public constant PRICE_PER_PITBULL = .07 ether;
    uint256 public constant MAX_PER_TRANSACTION = 8;

    string private baseURI;
    string private signVersion;
    address private signer;

    constructor(
        string memory name,
        string memory symbol,
        string memory _uri, string memory _signVersion) ERC721(name, symbol) {
        baseURI = _uri;
        signVersion = _signVersion;
        signer = msg.sender;
    }

    function updateSignVersion(string calldata _signVersion) external onlyOwner {
        signVersion = _signVersion;
    }

    function updateSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function _verify(address sender, uint256 maxMintAmount, bytes memory signature) internal view returns (bool) {
        return keccak256(abi.encodePacked(sender, signVersion, maxMintAmount))
            .toEthSignedMessageHash()
            .recover(signature) == signer;
    }
    
    function changeContractState(ContractState _state) external onlyOwner {
        currentState = _state;
    }

    function claimAngryPitbulls(uint256 _numberOfPitbulls, uint256 _maxMintAmount, bytes memory _signature) external payable nonReentrant{
        require(currentState == ContractState.PRESALE, "The whitelist is not active yet. Stay tuned.");
        require(_numberOfPitbulls > 0, "You cannot mint 0 Pitbulls.");
        require(SafeMath.add(_numMinted.current(), _numberOfPitbulls) <= MAX_PUBLIC_MINT, "The entire collection has been sold.");
        require(getNFTPrice(_numberOfPitbulls) <= msg.value, "Amount of Ether sent is not correct.");
        require(_verify(msg.sender, _maxMintAmount, _signature), "This signature is not verified. You are not on the whitelist.");
        require(SafeMath.add(addressMinted[msg.sender], _numberOfPitbulls) <= _maxMintAmount, "This amount exceeds the quantity you are allowed to mint during presale.");
        
        for(uint i = 0; i < _numberOfPitbulls; i++){
            uint256 tokenIndex = _tokenIdCounter.current();
            _numMinted.increment();
            _tokenIdCounter.increment();
            addressMinted[msg.sender]++;
            _safeMint(msg.sender, tokenIndex);   
        }
    }

    function mintAngryPitbulls(uint256 _numberOfPitbulls) external payable nonReentrant{
        require(currentState == ContractState.PUBLIC, "The public sale is not active yet. Stay Tuned.");
        require(_numberOfPitbulls > 0, "You cannot mint 0 Pitbulls.");
        require(_numberOfPitbulls <= MAX_PER_TRANSACTION, "You may only mint up to 8 per transaction");
        require(SafeMath.add(_numMinted.current(), _numberOfPitbulls) <= MAX_PUBLIC_MINT, "Exceeds maximum supply.");
        require(getNFTPrice(_numberOfPitbulls) <= msg.value, "Amount of Ether sent is not correct.");

        for(uint i = 0; i < _numberOfPitbulls; i++){
            uint256 tokenIndex = _tokenIdCounter.current();
            _numMinted.increment();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenIndex);   
        }
    }

    function airdropAngryPitbulls(uint256 _numberOfPitbulls) external onlyOwner {
        require(_numberOfPitbulls > 0, "You cannot mint 0 Pitbulls.");
        require(SafeMath.add(_numAirdroped.current(), _numberOfPitbulls) <= AIRDROP_RESERVE, "Exceeds maximum airdrop reserve.");

        for(uint i = 0; i < _numberOfPitbulls; i++){
            uint256 tokenId = _tokenIdCounter.current(); 
            _tokenIdCounter.increment();
            _numAirdroped.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function getNFTPrice(uint256 _amount) public pure returns (uint256) {
        return SafeMath.mul(_amount, PRICE_PER_PITBULL);
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