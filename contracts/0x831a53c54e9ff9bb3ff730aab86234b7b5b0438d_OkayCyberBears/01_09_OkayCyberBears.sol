//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OkayCyberBears is ERC721A, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    
    mapping(address => uint256) public NFTFreemintedbyAddress;

    uint public constant MAX_SUPPLY = 3333;
    uint public constant PRICE = 0.0069 ether;
    bool private PublicSaleOpen = true;
    bool private PresaleOpen = true;
    uint public TotalFreeMinted = 0;
    
    string public baseTokenURI;
    
    constructor(string memory baseURI) ERC721A("OkayCyberBears", "OCB") {
        setBaseURI(baseURI);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function PublicSaleStatus() public view returns (bool) {
        return PublicSaleOpen;
    }

    function PresaleStatus() public view returns (bool) {
        return PresaleOpen;
    }
    
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setPublicSaleStatus(bool _publicSaleStatus) public onlyOwner {
        PublicSaleOpen = _publicSaleStatus;
    }

    function setPresaleStatus(bool _presaleStatus) public onlyOwner {
        PresaleOpen = _presaleStatus;
    }

    function reserveNFTs() public onlyOwner {
        require(_totalMinted() + 102 < MAX_SUPPLY, "Not enough NFTs left to reserve");
        _safeMint(msg.sender, 102);
    }
    
    function mintNFTs(uint _count) public payable {
        require(PublicSaleOpen,"Public minting is not open!");
        require(_totalMinted() + _count <= MAX_SUPPLY, "Not enough NFTs left!");
        require(numberMinted(msg.sender) < 3, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");
        _safeMint(msg.sender, _count);
    }
    
    function preSale(uint _count) public payable {
        uint preSaleMaxMint = 1;
        uint preSaleMaxSupply = 1000;
        require(PresaleOpen ,"Presale minting is not open!");
        require(NFTFreemintedbyAddress[msg.sender] + _count <= preSaleMaxMint, "Cannot mint specified number of NFTs.");
        require(TotalFreeMinted + _count <= preSaleMaxSupply, "Not enough Presale NFTs left!");
        //require(_count > 0 && numberMinted(msg.sender) + _count <= preSaleMaxMint, "Cannot mint specified number of NFTs.");
        _safeMint(msg.sender, _count);
        NFTFreemintedbyAddress[msg.sender] += _count;
        TotalFreeMinted += _count;
    }
    
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}