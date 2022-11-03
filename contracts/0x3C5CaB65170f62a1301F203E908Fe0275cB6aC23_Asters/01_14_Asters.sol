// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


import "./ERC721A.sol";
import "./ERC721AQueryable.sol";

//@author ASTERS
//@title ASTERS

contract Asters is Ownable, ERC721A, ERC721AQueryable, ReentrancyGuard{
    using Strings for uint256;

    uint public constant MAX_SUPPLY = 3170;
    uint private constant MAX_WHITELIST = 3000;
    uint private constant MAX_DEVS = 170;
    uint private constant MAX_PUBLIC = MAX_SUPPLY - MAX_WHITELIST - MAX_DEVS;
    uint public MAX_MINT_PER_ADDRESS = 1;


    //0.5 ETHER INITIAL CONTRACT PRICE FOR SECURITY - THEN CHANGE TO 0 ETHER (FREE MINT)
    uint256 public COST = 0.5 ether;

    //quantity of tokens minted
    uint public devMintedQuantity = 0;


    bool public PAUSED = false; 
    bool public REVEALED = false;

    string private NOTREVEALED_TOKEN_URI;
    string private BASE_TOKEN_URI = '';  
 
    bytes32 private whitelistMerkleRoot; 

    uint256 public saleStartTime = 1667496600; //3 nov 2022 17:30:00 UTC
    uint256 public saleDuration = 8 hours;

    mapping (address => uint256 ) private amountWalletWhitelistSale;

    constructor(    
        string memory notRevealedURI,
        bytes32 _merkleRoot
    )ERC721A("Asters", "ASTERS"){
        NOTREVEALED_TOKEN_URI = notRevealedURI;
        whitelistMerkleRoot = _merkleRoot;
    }

    //MODIFIERS

    modifier callerIsUser(){
        require(tx.origin == msg.sender, "Only Users");
        _;
    }

    modifier ZeroCondition(uint _quantity){
        require(_quantity > 0, "Need to mint at least 1 NFT");
        _;
    }

    modifier whenNotPaused() {
        require(!PAUSED, "SmartContract Paused");
        _;
    }

    modifier onlyWhitelist(address _account, bytes32[] calldata _proof){
        require(isWhitelisted(_account, _proof), "Not Whitelisted");
        _;
    }

    //MERKLE-ROOT 

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        whitelistMerkleRoot = _merkleRoot; 
    }

    function isWhitelisted(address _account, bytes32[] calldata _proof) public view returns (bool){
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns(bytes32){
        return keccak256(abi.encodePacked(_account));
    }
    
    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool){
        return MerkleProof.verify(_proof, whitelistMerkleRoot, _leaf);
    }

    //WHITELIST-MINT

    function whitelistMint(uint _quantity, bytes32[] calldata _proof) external payable 
        callerIsUser
        ZeroCondition(_quantity)
        whenNotPaused()
        onlyWhitelist(msg.sender, _proof){

        require(getCurrentTime() >= saleStartTime, "Presale has not started yed"); 
        require(getCurrentTime() < saleStartTime + saleDuration, "Presale is finished");
        require(totalSupply() + _quantity <= MAX_WHITELIST + devMintedQuantity, "WHITELIST MINT: Max supply exceeded");
        require(amountWalletWhitelistSale[msg.sender] + _quantity <= MAX_MINT_PER_ADDRESS, "Max Mint Per Address Reached"); 
        require(msg.value >= COST * _quantity , "Need to send more ETH");

        amountWalletWhitelistSale[msg.sender] += _quantity;
        
        _safeMint(msg.sender, _quantity);

       
        
    }
    
    function pause(bool _state) public onlyOwner {
        PAUSED = _state;
    }
    
    //PUBLICSALE-MINT

    function publicSaleMint(uint _quantity) external payable 
        callerIsUser
        ZeroCondition(_quantity)
        whenNotPaused(){
            
        require(getCurrentTime() >= saleStartTime + saleDuration, "Whitelist sale has not been finished");
        require(totalSupply() + _quantity <= MAX_PUBLIC + MAX_WHITELIST + devMintedQuantity, "PUBLIC MINT: Max supply exceeded");
        require(amountWalletWhitelistSale[msg.sender] + _quantity <= MAX_MINT_PER_ADDRESS, "Max Mint Per Address Reached");
        require(msg.value >= COST * _quantity , "Need to send more ETH");

        amountWalletWhitelistSale[msg.sender] += _quantity;

        _safeMint(msg.sender, _quantity);
        
    }

    //MARKETING, ETC.
    
    function gift(address _account, uint256 quantity) external onlyOwner{
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Reached Max Supply"
        );
        require(devMintedQuantity + quantity <= MAX_DEVS, "Reached Max Devs Supply");
        devMintedQuantity += quantity;
        _safeMint(_account, quantity);
    }

    function devMint(uint256 quantity) external onlyOwner{
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Reached Max Supply"
        );
        require(devMintedQuantity + quantity <= MAX_DEVS, "Reached Max Devs Supply");
        devMintedQuantity += quantity;
        _safeMint(msg.sender, quantity);
    }
    
    //GETTERS

    function getCurrentTime() internal view returns (uint){
        return block.timestamp;
    }

    //SETTERS

    function setCostWEI(uint256 _cost) external onlyOwner{
        COST = _cost;
    }

    function setPreSaleStartTime(uint _saleStartTime) external onlyOwner{
        saleStartTime = _saleStartTime;
    }

    function setPreSaleDuration(uint _duration) external onlyOwner{
        saleDuration = _duration;
    }

    function setMaxMintPerAddress(uint _maxmint) external onlyOwner{
        MAX_MINT_PER_ADDRESS = _maxmint;
    }
    
    //METADATA URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId),"URI query for nonexistent token");

        if (!REVEALED){
            return NOTREVEALED_TOKEN_URI;
        }

        string memory base_token_uri = _baseURI();
        return 
            bytes(base_token_uri).length > 0
            ? string(abi.encodePacked(base_token_uri,tokenId.toString())): "";
    }

    function reveal() public onlyOwner{
        REVEALED = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
     return BASE_TOKEN_URI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        BASE_TOKEN_URI = baseURI;
    }

    function setNotRevealedURI(string calldata _notRevealedURI) external onlyOwner {
        NOTREVEALED_TOKEN_URI = _notRevealedURI;
    }
    
    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
        
}