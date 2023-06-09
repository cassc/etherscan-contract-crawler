// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VCXGen2 is ERC721A, Ownable, ReentrancyGuard
{
    uint public constant MAX_TOKENS = 10000; //This is your total supply limit
    uint public constant NUMBER_RESERVED_TOKENS = 100; //This is your reserved supply that can be used for marketing etc.
    uint public perAddressLimit = 1; //Max per wallet address limit for presale

    bool public saleIsActive = false; //Public Mint: You must activate each sale to open up minting

    uint public reservedTokensMinted = 0;
    string private _baseTokenURI; //The Base URI is the link copied from your IPFS Folder holding your collections json files that have the metadata and image links associated to each token ID
    mapping(address => uint) public addressMintedBalance;

    constructor() ERC721A("Venture Capital X Gen II", "VCXII") {} //Name of Project and Token "Ticker"

    function mintToken(uint256 amount) external nonReentrant //This function is for Public Mint and Presale Mint Parameters and Error Messages
    {
        require(saleIsActive, "Sale must be active to mint");
        require(addressMintedBalance[msg.sender] + amount <= perAddressLimit, "Max NFT per address exceeded");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(msg.sender.balance >= 0.03 ether, "You must have 0.03 ether to mint (this is used to help avoid bot attacks)");

        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function setPerAddressLimit(uint newLimit) external onlyOwner //Change max per wallet address last minute
    {
        perAddressLimit = newLimit;
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner //This Function is for minting your reserve which is also done through remix similar to how you flip minting sale states
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        reservedTokensMinted+= amount;
        _mint(to, amount);
    }
 
    ////
    //URI management part
    ////

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}