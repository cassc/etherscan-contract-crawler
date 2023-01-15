// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "./Opensea/DefaultOperatorFilterer.sol";

// ░██████╗██╗░░██╗██╗██████╗░░█████╗░░██████╗██╗░░██╗██╗░██████╗  ░█████╗░██╗░░░░░██╗░░░██╗██████╗░
// ██╔════╝██║░░██║██║██╔══██╗██╔══██╗██╔════╝██║░░██║██║██╔════╝  ██╔══██╗██║░░░░░██║░░░██║██╔══██╗
// ╚█████╗░███████║██║██████╦╝██║░░██║╚█████╗░███████║██║╚█████╗░  ██║░░╚═╝██║░░░░░██║░░░██║██████╦╝
// ░╚═══██╗██╔══██║██║██╔══██╗██║░░██║░╚═══██╗██╔══██║██║░╚═══██╗  ██║░░██╗██║░░░░░██║░░░██║██╔══██╗
// ██████╔╝██║░░██║██║██████╦╝╚█████╔╝██████╔╝██║░░██║██║██████╔╝  ╚█████╔╝███████╗╚██████╔╝██████╦╝
// ╚═════╝░╚═╝░░╚═╝╚═╝╚═════╝░░╚════╝░╚═════╝░╚═╝░░╚═╝╚═╝╚═════╝░  ░╚════╝░╚══════╝░╚═════╝░╚═════╝░
// ██╗░░██╗  ██████╗░██╗░░░██╗░██████╗░░█████╗░████████╗████████╗██╗  ░██████╗░██████╗░░█████╗░██╗░░░██╗██████╗░
// ╚██╗██╔╝  ██╔══██╗██║░░░██║██╔════╝░██╔══██╗╚══██╔══╝╚══██╔══╝██║  ██╔════╝░██╔══██╗██╔══██╗██║░░░██║██╔══██╗
// ░╚███╔╝░  ██████╦╝██║░░░██║██║░░██╗░███████║░░░██║░░░░░░██║░░░██║  ██║░░██╗░██████╔╝██║░░██║██║░░░██║██████╔╝
// ░██╔██╗░  ██╔══██╗██║░░░██║██║░░╚██╗██╔══██║░░░██║░░░░░░██║░░░██║  ██║░░╚██╗██╔══██╗██║░░██║██║░░░██║██╔═══╝░
// ██╔╝╚██╗  ██████╦╝╚██████╔╝╚██████╔╝██║░░██║░░░██║░░░░░░██║░░░██║  ╚██████╔╝██║░░██║╚█████╔╝╚██████╔╝██║░░░░░
// ╚═╝░░╚═╝  ╚═════╝░░╚═════╝░░╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░░░░╚═╝░░░╚═╝  ░╚═════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚═╝░░░░░

// Powered by https://nalikes.com

contract ShiboshisClubXBugattiGroup is ERC721AQueryable, DefaultOperatorFilterer, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public uriSuffix = "";
    string public baseURI;
    string public claimedURI;

    uint256 public cost = 0.14 ether;
    uint256 public maxSupply = 299;
    uint256 public maxMintAmountPerTx = 5;
    
    bool public paused = false;

    mapping(uint256 => bool) public claimed;

    constructor() ERC721A("Shiboshis Club X Bugatti Group", "SCB") {}

    //******************************* MODIFIERS

    modifier mintCompliance(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, "MINT: Max Supply Exceeded.");
        require(_mintAmount <= maxMintAmountPerTx, "MINT: Invalid Amount.");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "MINT: Insufficient funds.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract Paused.");
        _;
    }

    //******************************* MINT

    function mint(uint256 _mintAmount) public payable notPaused mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {

        require(tx.origin == msg.sender, "PUBLIC Mint: Caller is another contract.");
        _safeMint(_msgSender(), _mintAmount);
    }

    // @dev Admin mint
    function mintForAddress(address _receiver, uint256 _mintAmount) public notPaused mintCompliance(_mintAmount) onlyOwner {

        _safeMint(_receiver, _mintAmount);
    }

    //******************************* OVERRIDES

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (claimed[_tokenId]) {
            string memory currentClaimedURI = claimedURI;
            return bytes(currentClaimedURI).length > 0 ? string(abi.encodePacked(currentClaimedURI, _tokenId.toString(), uriSuffix)) : "";        
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";    
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //******************************* CRUD

    // URI'S

    function setBaseURI(string memory _metadataURI) public onlyOwner {
        baseURI = _metadataURI;
    }

    function setClaimedUri(string memory _claimedURI) public onlyOwner {
        claimedURI = _claimedURI;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    // UINT'S

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(_newMaxSupply >= totalSupply() && _newMaxSupply <= maxSupply, "Invalid Max Supply.");
        maxSupply = _newMaxSupply;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    // BOOL's

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    // CLAIM

    function claim(uint256[] calldata _tokenIds) external notPaused onlyOwner {

        for (uint256 i = 0; i < _tokenIds.length; i ++) {
            require(!claimed[_tokenIds[i]], "CLAIM: Token Already Claimed.");
            claimed[_tokenIds[i]] = true;
        }
    }

    //******************************* WITHDRAW

    function withdraw() public onlyOwner nonReentrant {
        
        uint256 balance = address(this).balance;

        bool success;
        (success, ) = payable(0x5999d8aB90A1C460fB63fbA06bbBbe3D6aF64183).call{value: balance}("");
        require(success, "Transaction Unsuccessful");
    }
}