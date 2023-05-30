// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract CookiesNKicks is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    enum ContractState { PAUSED, PRESALE_ONE, PRESALE_TWO, PUBLIC }
    ContractState public currentState = ContractState.PAUSED;

    mapping(address => uint256) public addressMinted; 
    
    // Total Supply: 6,777
    uint256 public MAX_TOTAL_MINT = 6542;
    uint256 public AIRDROP_RESERVE = 235; // For original holders of CNK World
    uint256 public PRICE_PER_COOKIE = .08 ether;
    uint256 public MAX_PER_TRANSACTION = 3;

    string private baseURI;
    string private signVersion;
    address private signer;

    constructor(
        string memory _uri, 
        string memory _signVersion) ERC721("Cookies N Kicks", "CNK") {
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
            PRICE_PER_COOKIE = .08 ether;
            MAX_TOTAL_MINT = 3000;
        }
        else if(currentState == ContractState.PRESALE_TWO) {
            PRICE_PER_COOKIE = .08 ether;
            MAX_TOTAL_MINT = 5000;
        }
        else if(currentState == ContractState.PUBLIC){
            PRICE_PER_COOKIE = .1 ether;
            MAX_TOTAL_MINT = 6542;
        }
    }

    function claimCookies(uint256 _numberOfCookies, uint256 _maxMintAmount, bytes memory _signature) external payable{
        require(
            (currentState == ContractState.PRESALE_ONE ||
            currentState == ContractState.PRESALE_TWO), "The whitelist is not active yet. Stay tuned.");
        require(_numberOfCookies > 0, "You cannot mint 0 Cookies.");
        require(SafeMath.add(_tokenIdCounter.current(), _numberOfCookies) <= MAX_TOTAL_MINT, "The entire presale has been sold. Check back for public mint.");
        require(getNFTPrice(_numberOfCookies) <= msg.value, "Amount of Ether sent is not correct.");
        require(_verify(msg.sender, _maxMintAmount, _signature), "This signature is not verified. You are not on the whitelist.");
        require(SafeMath.add(addressMinted[msg.sender], _numberOfCookies) <= _maxMintAmount, "This amount exceeds the quantity you are allowed to mint during presale.");
        
        for(uint i = 0; i < _numberOfCookies; i++){
            uint256 tokenIndex = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            addressMinted[msg.sender]++;
            _safeMint(msg.sender, tokenIndex);   
        }
    }

    function mintCookies(uint256 _numberOfCookies) external payable{
        require(currentState == ContractState.PUBLIC, "The public sale is not active yet. Stay Tuned.");
        require(_numberOfCookies > 0 && 
            _numberOfCookies <= MAX_PER_TRANSACTION, "Don't be greedy: too many per transaction.");
        require(SafeMath.add(_tokenIdCounter.current(), _numberOfCookies) <= MAX_TOTAL_MINT, "Exceeds maximum supply.");
        require(getNFTPrice(_numberOfCookies) <= msg.value, "Amount of Ether sent is not correct.");

        for(uint i = 0; i < _numberOfCookies; i++){
            uint256 tokenIndex = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenIndex);   
        }
    }

    function airdropCookies(address[] calldata _addresses) external onlyOwner {
        require(SafeMath.add(_tokenIdCounter.current(), _addresses.length) <= MAX_TOTAL_MINT + AIRDROP_RESERVE, "Exceeds maximum supply.");        

        for(uint i = 0; i < _addresses.length; i++){
            uint256 tokenId = _tokenIdCounter.current(); 
            _tokenIdCounter.increment();
            _safeMint(_addresses[i], tokenId);
        }
    }

     function getNFTPrice(uint256 _amount) public view returns (uint256) {
        return SafeMath.mul(_amount, PRICE_PER_COOKIE);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setMaxes(uint256 _maxTotalMint, uint256 _maxPerTransaction, uint256 _pricePerCookie) external onlyOwner {
        require(totalSupply() <= _maxTotalMint, "_maxTotalMint not large enough");

        MAX_TOTAL_MINT = _maxTotalMint;
        MAX_PER_TRANSACTION = _maxPerTransaction;
        PRICE_PER_COOKIE = _pricePerCookie;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}