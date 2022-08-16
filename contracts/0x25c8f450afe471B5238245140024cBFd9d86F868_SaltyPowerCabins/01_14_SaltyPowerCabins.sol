// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SaltyPowerCabins is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 261;
    uint256 public constant AIRDROP_BUFFER = 10;
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant MAX_MINT = 5;    

    Counters.Counter private _tokenIdCounter;
    Counters.Counter public airdropsSent;

    address private _signer;
    string public baseURI;

    enum ContractState { PAUSED, WHITELIST }
    ContractState public currentState = ContractState.PAUSED;

    constructor(address __signer, string memory _URI) ERC721("SaltyPowerCabins", "SPC") {
        _signer = __signer;
        baseURI = _URI;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    // Sets a new contract state: PAUSED, WHITELIST
    function setContractState(ContractState _newState) external onlyOwner {
        currentState = _newState;
    }

    // Returns the total supply minted
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Returns the base uri
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Verifies that the sender is whitelisted
    function _verifySignature(address sender, bytes memory signature) internal view returns (bool) {
        return keccak256(abi.encodePacked(sender))
            .toEthSignedMessageHash()
            .recover(signature) == _signer;
    }

    function airdrop(uint256 airdropAmount, address to) public onlyOwner {
        require(airdropAmount > 0, "Airdrop != 0");
        require(airdropsSent.current() + airdropAmount <= AIRDROP_BUFFER, "Airdropping exceeded");
        require(airdropAmount + _tokenIdCounter.current() <= MAX_SUPPLY , "Airdrop > Max");

        for(uint i = 0; i < airdropAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            airdropsSent.increment();
            _safeMint(to, tokenId);
        } 
    }

    function mint(uint256 mintAmount, bytes memory _signature) public payable nonReentrant {
        require(currentState == ContractState.WHITELIST, "Whitelist not in session");
        require(_verifySignature(msg.sender, _signature), "You are not on the whitelist");
        require(mintAmount > 0, "mint < 0");
        require(mintAmount + _tokenIdCounter.current() <= MAX_SUPPLY - AIRDROP_BUFFER + airdropsSent.current(), "Minting more than max supply");
        require(mintAmount <= MAX_MINT, "Max mint is 5");
        require(msg.value == PRICE * mintAmount, "Eth sent < total");

        for(uint i = 0; i < mintAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    // Withdraw funds
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }
}