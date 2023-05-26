// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// @author: LoMel
contract TheDonutShop is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    enum ContractState { PAUSED, PRESALE, PUBLIC }
    ContractState public currentState = ContractState.PAUSED;

    uint256 public MAX_TOTAL_MINT = 7777;
    uint256 public MAX_PER_TRANSACTION = 5;
    uint256 public MAX_PER_WALLET_FOR_PUBLIC = 10;
    uint256 public PRICE_PER_DONUT = .12 ether;

    mapping(address => uint256) public addressMinted; 

    string private baseURI;
    string private baseURISuffix;
    string private signVersion;
    address private signer;

    constructor(
        string memory _base, 
        string memory _suffix,
        string memory _signVersion) ERC721("The Donut Shop", "DONUT") {
        baseURI = _base;
        baseURISuffix = _suffix;
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
        if(currentState == ContractState.PRESALE) {
            PRICE_PER_DONUT = .12 ether;
            MAX_TOTAL_MINT = 4444;
        }
        else if(currentState == ContractState.PUBLIC) {
            PRICE_PER_DONUT = .16 ether;
            MAX_TOTAL_MINT = 7777;
        }
    }

    function claimDonuts(uint256 _numberOfDonuts, uint256 _maxMintAmount, bytes memory _signature) external payable {
        require(currentState == ContractState.PRESALE, "The whitelist is not active yet. Stay tuned.");
        require(SafeMath.add(_tokenIdCounter.current(), _numberOfDonuts) <= MAX_TOTAL_MINT, "The entire presale has been sold. Check back for public mint.");
        require(getNFTPrice(_numberOfDonuts) <= msg.value, "Amount of Ether sent is not correct.");
        require(_verify(msg.sender, _maxMintAmount, _signature), "This signature is not verified. You are not on the whitelist.");
        require(SafeMath.add(addressMinted[msg.sender], _numberOfDonuts) <= _maxMintAmount, "This amount exceeds the quantity you are allowed to mint during presale.");
        
        for(uint i = 0; i < _numberOfDonuts; ++i){
            uint256 tokenIndex = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            ++addressMinted[msg.sender];
            _safeMint(msg.sender, tokenIndex);   
        }
    }

    function mintDonuts(uint256 _numberOfDonuts) external payable {
        require(currentState == ContractState.PUBLIC, "The public sale is not active yet. Stay Tuned.");
        require(_numberOfDonuts <= MAX_PER_TRANSACTION, "Don't be greedy. That's too many.");
        require(SafeMath.add(addressMinted[msg.sender], _numberOfDonuts) <= MAX_PER_WALLET_FOR_PUBLIC, "This amount exceeds the quantity you are allowed to mint during public.");
        require(SafeMath.add(_tokenIdCounter.current(), _numberOfDonuts) <= MAX_TOTAL_MINT, "Exceeds maximum supply.");
        require(getNFTPrice(_numberOfDonuts) <= msg.value, "Amount of Ether sent is not correct.");

        for(uint i = 0; i < _numberOfDonuts; ++i){
            uint256 tokenIndex = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            ++addressMinted[msg.sender];
            _safeMint(msg.sender, tokenIndex);   
        }
    }

    function airdropDonuts(address[] calldata _to, uint256[] calldata _numberOfDonuts) external onlyOwner {
        require(_to.length == _numberOfDonuts.length, "The arrays must be the same length.");

        uint256 sum;
        for(uint256 i = 0; i < _numberOfDonuts.length; ++i){
            sum += _numberOfDonuts[i];
        }
        require(SafeMath.add(_tokenIdCounter.current(), sum) <= MAX_TOTAL_MINT);

        for(uint i = 0; i < _to.length; ++i){
            for(uint j = 0; j < _numberOfDonuts[i]; ++j){
                uint256 tokenId = _tokenIdCounter.current(); 
                _tokenIdCounter.increment();
                _safeMint(_to[i], tokenId);
            }
        }
    }

    function getNFTPrice(uint256 _amount) public view returns (uint256) {
        return SafeMath.mul(_amount, PRICE_PER_DONUT);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function setMaxes(uint256 _maxTotalMint, uint256 _maxPerTransaction, uint256 _pricePerDonut) external onlyOwner {
        require(totalSupply() <= _maxTotalMint, "_maxTotalMint not large enough");

        MAX_TOTAL_MINT = _maxTotalMint;
        MAX_PER_TRANSACTION = _maxPerTransaction;
        PRICE_PER_DONUT = _pricePerDonut;
    }

    function setBaseURI(string calldata _base, string calldata _suffix) external onlyOwner {
        baseURI = _base;
        baseURISuffix = _suffix;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "The Donut Shop: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseURISuffix));
    }
}