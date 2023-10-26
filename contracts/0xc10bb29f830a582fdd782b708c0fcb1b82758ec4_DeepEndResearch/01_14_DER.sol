// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DeepEndResearch is ERC721A, Ownable, ReentrancyGuard
{
    using Strings for string;

    uint public constant MAX_TOKENS = 690; //This is your total supply limit
    uint public PRESALE_LIMIT = 690; //This is your limit
    uint public presaleTokensSold = 0;
    uint public constant NUMBER_RESERVED_TOKENS = 50; 
    uint256 public PRICE = 0.18 ether;
    uint public perAddressLimit = 2; 

    bool public saleIsActive = false; 
    bool public preSaleIsActive = false; 
    bool public whitelist = true;
    bool public revealed = false;

    uint public reservedTokensMinted = 0;
    string private _baseTokenURI; 
    string public notRevealedUri; 
    bytes32 root;
    mapping(address => uint) public addressMintedBalance;

    //-------------
    // payment splitter
    //-------------

    address payable private devguy = payable(0x7ea9114092eC4379FFdf51bA6B72C71265F33e96); //Payment Splitter 

    constructor() ERC721A("DeepEndResearch", "DER") {} //Name of Project and Token "Ticker"

    function mintToken(uint256 amount, bytes32[] memory proof) external payable //This function is for Public Mint and Presale Mint Parameters and Error Messages
    {
        require(preSaleIsActive || saleIsActive, "Sale must be active to mint");

        require(!preSaleIsActive || presaleTokensSold + amount <= PRESALE_LIMIT, "Purchase would exceed max supply");
        require(addressMintedBalance[msg.sender] + amount <= perAddressLimit, "Max NFT per address exceeded");
        require(!whitelist || verify(proof), "Address not whitelisted");

        require(amount > 0 && amount <= 2, "Max 2 NFTs per transaction");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");

        if (preSaleIsActive) {
            presaleTokensSold += amount;
        }

        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

   
    function setPrice(uint256 newPrice) external onlyOwner
    {
        PRICE = newPrice;
    }

    function setPresaleLimit(uint newLimit) external onlyOwner  
    {
        PRESALE_LIMIT = newLimit;
    }

    function setPerAddressLimit(uint newLimit) external onlyOwner 
    {
        perAddressLimit = newLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() external onlyOwner
    {
        preSaleIsActive = !preSaleIsActive;
    }

    function flipWhitelistingState() external onlyOwner
    {
        whitelist = !whitelist;
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner //This Function is for minting your reserve
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        reservedTokensMinted+= amount;
        _safeMint(to, amount);
    }


    function withdraw() external nonReentrant
    {
        require(msg.sender == devguy || msg.sender == owner(), "Invalid sender");
        (bool success, ) = devguy.call{value: address(this).balance / 100 * 30}(""); 
        (bool success2, ) = owner().call{value: address(this).balance}(""); 
        require(success, "Transfer 1 failed");
        require(success2, "Transfer 2 failed");
    }

    function setRoot(bytes32 _root) external onlyOwner
    {
        root = _root;
    }

    function verify(bytes32[] memory proof) internal view returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
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

        if(revealed == false)
        {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}