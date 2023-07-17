// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Created By: LoMel
contract DemiGodsUniverse is ERC721Enumerable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _numAirdroped;
    Counters.Counter private _numMinted;
    
    enum ContractState { PAUSED, PRESALE_ONE, PRESALE_TWO, PUBLIC }
    ContractState public currentState = ContractState.PAUSED;

    // Total supply 10,000
    uint256 public maxTotalMint = 2000; // increments based on contract state
    uint256 public constant AIRDROP_RESERVE = 50; // used to help market the project
    
    mapping(address => uint256) public addressMinted; 

    uint256 public pricePerDemiGod = .07 ether;
    uint256 public MAX_PER_TRANSACTION = 10;

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
        if(currentState == ContractState.PRESALE_ONE) {
            pricePerDemiGod = .07 ether;
            maxTotalMint = 2000;
        }
        else if(currentState == ContractState.PRESALE_TWO) {
            pricePerDemiGod = .1 ether;
            maxTotalMint = 6000;
        }
        else if(currentState == ContractState.PUBLIC) {
            pricePerDemiGod = .15 ether;
            maxTotalMint = 9950;
        }
    }

    function claimDemiGods(uint256 _numberOfDemiGods, uint256 _maxMintAmount, bytes memory _signature) external payable nonReentrant{
        require(
            (currentState == ContractState.PRESALE_ONE ||
            currentState == ContractState.PRESALE_TWO), "The whitelist is not active yet. Stay tuned.");
        require(_numberOfDemiGods > 0, "You cannot mint 0 Demi Gods.");
        require(SafeMath.add(_numMinted.current(), _numberOfDemiGods) <= maxTotalMint, "The entire presale has been sold. Check back for public mint.");
        require(getNFTPrice(_numberOfDemiGods) <= msg.value, "Amount of Ether sent is not correct.");
        require(_verify(msg.sender, _maxMintAmount, _signature), "This signature is not verified. You are not on the whitelist.");
        require(SafeMath.add(addressMinted[msg.sender], _numberOfDemiGods) <= _maxMintAmount, "This amount exceeds the quantity you are allowed to mint during presale.");
        
        for(uint i = 0; i < _numberOfDemiGods; i++){
            uint256 tokenIndex = _tokenIdCounter.current();
            _numMinted.increment();
            _tokenIdCounter.increment();
            addressMinted[msg.sender]++;
            _safeMint(msg.sender, tokenIndex);   
        }
    }

    function mintDemiGods(uint256 _numberOfDemiGods) external payable nonReentrant{
        require(currentState == ContractState.PUBLIC, "The public sale is not active yet. Stay Tuned.");
        require(_numberOfDemiGods > 0, "You cannot mint 0 Demi Gods.");
        require(_numberOfDemiGods <= MAX_PER_TRANSACTION, "You can only mint 15 Demi Gods per transaction.");
        require(SafeMath.add(_numMinted.current(), _numberOfDemiGods) <= maxTotalMint, "Exceeds maximum supply.");
        require(getNFTPrice(_numberOfDemiGods) <= msg.value, "Amount of Ether sent is not correct.");

        for(uint i = 0; i < _numberOfDemiGods; i++){
            uint256 tokenIndex = _tokenIdCounter.current();
            _numMinted.increment();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenIndex);   
        }
    }

    function airdropDemiGod(uint256 _numberOfDemiGods) external onlyOwner {
        require(_numberOfDemiGods > 0, "You cannot mint 0 Demi Gods.");
        require(SafeMath.add(_numAirdroped.current(), _numberOfDemiGods) <= AIRDROP_RESERVE, "Exceeds maximum airdrop reserve.");

        for(uint i = 0; i < _numberOfDemiGods; i++){
            uint256 tokenId = _tokenIdCounter.current(); 
            _tokenIdCounter.increment();
            _numAirdroped.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

     function getNFTPrice(uint256 _amount) public view returns (uint256) {
        return SafeMath.mul(_amount, pricePerDemiGod);
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